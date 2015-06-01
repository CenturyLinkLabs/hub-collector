require_relative 'api'
require 'pg'

conn = PG.connect(dbname: 'hub', user: 'hub', password: 'foo', host: '127.0.0.1')

update = "UPDATE repos"\
  " SET description=$2, is_trusted=$3, is_official=$4, is_automated=$5, star_count=$6, updated_at=current_timestamp"\
  " WHERE name=$1"

insert = 'INSERT INTO repos'\
  ' (name, description, is_trusted, is_official, is_automated, star_count, updated_at)'\
  ' SELECT $1, $2, $3, $4, $5, $6, current_timestamp'

stmt = conn.prepare("upsert_repo", "WITH upsert AS (#{update} RETURNING *) #{insert} WHERE NOT EXISTS (SELECT * FROM upsert);")

('aa'..'zz').each do |q|
  i, max = 1, 1

  loop do
    break if i > max
    results = search(q, i, 100)
    max = results['num_pages']
    puts "#{q}, page #{i} of #{max}"

    results['results'].each do |res|
      begin
        conn.exec_prepared("upsert_repo", [
          res['name'], 
          res['description'], 
          res['is_trusted'], 
          res['is_official'], 
          res['is_automated'], 
          res['star_count']
        ])      
      rescue PG::UniqueViolation 
      end
    end

    i += 1
    sleep(1/2)
  end

  conn.exec("UPDATE last_term SET term = '#{q}'")
end
