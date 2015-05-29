require_relative 'api'
require 'pg'

conn = PG.connect(dbname: 'hub', user: 'hub', password: 'foo', host: '127.0.0.1')
stmt = conn.prepare("insert_image", "INSERT INTO images (name, description, is_trusted, is_official, is_automated, star_count) VALUES ($1, $2, $3, $4, $5, $6);")

('aa'..'zz').each do |q|
  i, max = 1, 1

  loop do
    break if i > max
    results = search(q, i)
    max = results['num_pages']
    puts "#{q}, page #{i} of #{max}"

    results['results'].each do |res|
      begin
        conn.exec_prepared("insert_image", [
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
    sleep(1)
  end

  conn.exec("UPDATE last_term SET term = '#{q}'")
  sleep(5)
end
