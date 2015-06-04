require_relative 'api'
require 'pg'

select_tags = 'SELECT repos.name AS repo_name, tags.id AS tag_id, tags.name AS tag_name, layers.layer_id'\
  ' FROM repos, tags, layers'\
  " WHERE repos.id = tags.repo_id AND tags.layer_id = layers.id"

select_layer = 'SELECT id, layer_id, parent_id from layers WHERE layer_id = $1'

update_layer = 'UPDATE layers SET parent_id = $2 WHERE layer_id = $1'

insert_layer = 'INSERT INTO layers'\
  ' (layer_id, parent_id, updated_at)'\
  ' SELECT $1, $2, current_timestamp RETURNING id'

insert_join = 'INSERT INTO tag_layers (tag_id, layer_id) VALUES ($1, $2)'

conn = PG.connect(dbname: 'hub', user: 'hub', password: 'foo', host: '127.0.0.1')

conn.prepare('select_layer', select_layer)
conn.prepare('insert_layer', insert_layer)
conn.prepare('update_layer', update_layer)
conn.prepare('insert_join', insert_join)

res = conn.exec(select_tags)

res.each do |tag|
  tag_id = tag['tag_id']

  begin
    puts "#{tag['repo_name']}:#{tag['tag_name']}"
    auth = get_auth(tag['repo_name'])
    ancestry = get_ancestry(tag['layer_id'], auth)

    parent_id = nil
    ancestry.reverse.each do |layer_id|

      layers = conn.exec_prepared('select_layer', [layer_id])
      if layers.count == 0
        res = conn.exec_prepared('insert_layer', [layer_id, parent_id])
        layer = res[0]
      else
        layer = layers[0]
        
        if layer['parent_id'].nil?
          conn.exec_prepared('update_layer', [layer_id, parent_id])
        end
      end

      begin
        conn.exec_prepared('insert_join', [tag_id, layer['id']])
      rescue PG::UniqueViolation
      end

      parent_id = layer['id']
    end
    
  rescue => ex
    puts "ERROR: #{ex}"
  end
  sleep(1)
end
