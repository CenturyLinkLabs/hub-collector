require 'pg'

$dbname = ENV['DB_NAME'] || 'hub'
$user = ENV['DB_USER'] || 'hub'
$password = ENV['DB_PASSWORD'] || 'hub'
$host = ENV['DB_HOST'] || '127.0.0.1'
$port = ENV['DB_PORT'] || '5432'

def conn
  $conn ||= PG.connect(host: $host, port: $port, dbname: $dbname, user: $user, password: $password)
end
