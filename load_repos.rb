require_relative 'api'
require_relative 'db'
require 'time'

update = 'UPDATE repos'\
  ' SET description=$2, is_trusted=$3, is_official=$4, is_automated=$5, star_count=$6, updated_at=current_timestamp'\
  ' WHERE name=$1'

insert = 'INSERT INTO repos'\
  ' (name, description, is_trusted, is_official, is_automated, star_count, updated_at, last_loaded)'\
  ' SELECT $1, $2, $3, $4, $5, $6, current_timestamp, \'1974-02-12\''

conn.prepare('upsert', "WITH upsert AS (#{update} RETURNING *) #{insert} WHERE NOT EXISTS (SELECT * FROM upsert);")

# Forever
loop do
  puts "start crawl: #{Time.now}"

  # Each search term
  ('aa'..'zz').to_a.shuffle.each do |q|
    i, max = 1, 1

    # Each page of results
    loop do
      break if i > max

      begin
        results = search(q, i, 100)
        max = results['num_pages']

        # Each result
        results['results'].each do |res|
          begin
            conn.exec_prepared('upsert', [
              res['name'],
              res['description'],
              res['is_trusted'],
              res['is_official'],
              res['is_automated'],
              res['star_count']
            ])
          rescue => ex
            puts "ERROR: #{ex}"
          end
        end
      rescue => ex
        puts "ERROR: #{ex}"
      end

      i += 1
      sleep(2)
    end

    conn.exec("UPDATE last_term SET term = '#{q}'")
  end
end
