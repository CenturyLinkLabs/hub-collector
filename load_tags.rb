require_relative 'api'
require 'pg'

insert_layer = 'INSERT INTO layers (layer_id, updated_at) VALUES ($1, current_timestamp) RETURNING id'
select_layer = 'SELECT id FROM layers WHERE layer_id=$1'
insert_tag = 'INSERT INTO tags (repo_id, name, layer_id, updated_at) SELECT $1, $2, $3, current_timestamp'
update_tag = 'UPDATE tags SET layer_id=$3, updated_at=current_timestamp WHERE repo_id=$1 AND name=$2'
upsert_tag = "WITH upsert AS (#{update_tag} RETURNING *) #{insert_tag} WHERE NOT EXISTS (SELECT * FROM upsert);"

conn = PG.connect(dbname: 'hub', user: 'hub', password: 'foo', host: '127.0.0.1')
conn.prepare('insert_layer', insert_layer)
conn.prepare('select_layer', select_layer)
conn.prepare('upsert_tag', upsert_tag)

res = conn.exec('SELECT id, name FROM repos')

res.each do |repo|
  begin
    auth = get_auth(repo['name'])
    tags = list_tags(repo['name'], auth)

    tags.each do |name, layer_id|
      puts "#{repo['name']}:#{name} - #{layer_id}"

      layer_record = begin
        conn.exec_prepared('insert_layer', [layer_id])
      rescue PG::UniqueViolation
        conn.exec_prepared('select_layer', [layer_id])
      end

      begin
        conn.exec_prepared('upsert_tag', [repo['id'], name, layer_record[0]['id']])
      rescue PG::UniqueViolation
      end
    end

    sleep(1)
  rescue => ex
    puts "### FAIL: #{repo['name']}"
    puts ex
  end
end
