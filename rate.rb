require 'pg'
require 'time'


conn = PG.connect(dbname: 'hub', user: 'hub', host: '127.0.0.1', password: 'foo')
res = conn.exec("SELECT count(*) as count FROM images")
x = res[0]['count'].to_i

loop do
  sleep(60)
  res = conn.exec("SELECT count(*) as count FROM images")
  y = res[0]['count'].to_i
  puts "#{Time.now}: #{y - x}"
  x = y
end
