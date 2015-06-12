require_relative 'api'
require_relative 'db'
require 'time'

conn.prepare('select_tags',                 'SELECT id FROM tags WHERE repo_id=$1')
conn.prepare('delete_tag_layers_by_tag_id', 'DELETE FROM tag_layers WHERE tag_id=$1')
conn.prepare('delete_tag',                  'DELETE FROM tags WHERE id=$1')

conn.prepare('select_layer', 'SELECT id, layer_id, parent_id from layers WHERE layer_id=$1')
conn.prepare('insert_layer', 'INSERT INTO layers'\
  ' (layer_id, parent_id, updated_at)'\
  ' VALUES ($1, $2, current_timestamp) RETURNING id')

conn.prepare('insert_tag', 'INSERT INTO tags (repo_id, name, updated_at) VALUES ($1, $2, current_timestamp) RETURNING id')
conn.prepare('update_tag', 'UPDATE tags SET layer_id=$2, updated_at=current_timestamp WHERE id=$1')

conn.prepare('insert_join', 'INSERT INTO tag_layers (tag_id, layer_id) VALUES ($1, $2)')

conn.prepare('update_repo', 'UPDATE repos SET last_loaded=current_timestamp WHERE id=$1')

conn.prepare('mark_repo', 'UPDATE repos SET marked = true WHERE id=$1')

def delete_repo_tags(repo_id)
  conn.transaction do |c|
    tags = c.exec_prepared('select_tags', [repo_id])
    tags.each do |tag|
      c.exec_prepared('delete_tag_layers_by_tag_id', [tag['id']])
      c.exec_prepared('delete_tag', [tag['id']])
    end
  end
end

def load_ancestry(tag_rec_id, layer_id, auth)

  ancestry = get_ancestry(layer_id, auth)

  layer_rec_id = nil
  parent_rec_id = nil
  ancestry.reverse.each do |layer_id|

    conn.transaction do |c|
      # Insert or find layer (many layers will already exist)
      layers = c.exec_prepared('select_layer', [layer_id])

      if layers.count == 0
        layer = c.exec_prepared('insert_layer', [layer_id, parent_rec_id])[0]
      else
        layer = layers[0]
      end

      layer_rec_id = layer['id']

      # Insert join between tag and layer
      c.exec_prepared('insert_join', [tag_rec_id, layer_rec_id])
    end

    parent_rec_id = layer_rec_id
  end

  layer_rec_id
end

# Forever
loop do
  puts "start crawl: #{Time.now}"

  s = 'SELECT repos.id, repos.name'\
    ' FROM repos'\
    ' LEFT JOIN tags ON repos.id = tags.repo_id'\
    ' LEFT JOIN tag_layers ON tags.id = tag_layers.tag_id'\
    ' WHERE tag_layers.tag_id IS NULL'\
    ' GROUP BY repos.id, repos.name'

  #repos = conn.exec(s)
  repos = conn.exec('SELECT id, name FROM repos ORDER BY last_loaded ASC')

  repos.each do |repo|
    repo_id = repo['id']
    repo_name = repo['name']
    puts "REPO: #{repo_name}"

    delete_repo_tags(repo_id)

    begin
      auth = get_auth(repo_name)
      tags = list_tags(repo_name, auth)

      tags.each do |name, tag_layer_id|
        puts "  TAG: #{name}"

        begin
          # Insert tag (minus layer_id)
          tag = conn.exec_prepared('insert_tag', [repo_id, name])
          tag_rec_id = tag[0]['id']

          layer_rec_id = load_ancestry(tag_rec_id, tag_layer_id, auth)

          # Update tag (w/ layer_id this time)
          conn.exec_prepared('update_tag', [tag_rec_id, layer_rec_id])
        rescue => ex
          puts "ERROR: #{ex} (#{repo_name}:#{name})"
        end

        sleep(1)
      end

      conn.exec_prepared('update_repo', [repo_id])
    rescue NotFoundError
      conn.exec_prepared('mark_repo', [repo_id])
    rescue => ex
      puts "ERROR: #{ex} (#{repo_name})"
    end
  end
end
