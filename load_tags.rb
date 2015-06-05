require_relative 'api'
require_relative 'db'
require 'time'

insert_layer = 'INSERT INTO layers (layer_id, updated_at) VALUES ($1, current_timestamp) RETURNING id'
select_layer = 'SELECT id FROM layers WHERE layer_id=$1'

insert_tag = 'INSERT INTO tags (repo_id, name, layer_id, updated_at) SELECT $1, $2, $3, current_timestamp'
update_tag = 'UPDATE tags SET layer_id=$3, updated_at=current_timestamp WHERE repo_id=$1 AND name=$2'
upsert_tag = "WITH upsert AS (#{update_tag} RETURNING *) #{insert_tag} WHERE NOT EXISTS (SELECT * FROM upsert);"

mark_repo = 'UPDATE repos SET marked = true WHERE id = $1'

conn.prepare('insert_layer', insert_layer)
conn.prepare('select_layer', select_layer)
conn.prepare('upsert_tag', upsert_tag)
conn.prepare('mark_repo', mark_repo)

# Forever
loop do
  puts "start crawl: #{Time.now}"

  repos = conn.exec('SELECT id, name FROM repos ORDER BY updated_at DESC')

  repos.each do |repo|
    repo_id = repo['id']
    repo_name = repo['name']

    begin
      auth = get_auth(repo_name)
      tags = list_tags(repo_name, auth)

      tags.each do |name, layer_id|
        begin
          layer_record = begin
            conn.exec_prepared('insert_layer', [layer_id])
          rescue PG::UniqueViolation
            conn.exec_prepared('select_layer', [layer_id])
          end

          conn.exec_prepared('upsert_tag', [repo_id, name, layer_record[0]['id']])
        rescue => ex
          puts "ERROR: #{ex} (#{repo_name})"
        end
      end

    rescue NotFoundError
      conn.exec_prepared('mark_repo', [repo_id])
    rescue => ex
      puts "ERROR: #{ex} (#{repo_name})"
    end

    sleep(1)
  end
end
