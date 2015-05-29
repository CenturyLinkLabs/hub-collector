require 'net/http'
require 'json'
require 'pg'

def search(query, page=1)
  try = 1
  begin
    uri = URI("https://index.docker.io/v1/search?q=#{query}&page=#{page}")

    req = Net::HTTP::Get.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

  JSON.parse(res.body)
  rescue => ex
    if try == 1
      try += 1
      retry
    else
      raise ex
    end
  end
end

def get_auth(repo)
  uri = URI("https://index.docker.io/v1/repositories/#{repo}/images")

  req = Net::HTTP::Get.new(uri)
  req['X-Docker-Token'] = true

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
    
  res = http.start do |http|
    http.request(req)
  end

  {
    token: res['X-Docker-Token'],
    endpoint: res['X-Docker-Endpoints']
  }
end

def list_tags(repo, auth)
  uri = URI("https://#{auth[:endpoint]}/v1/repositories/#{repo}/tags")

  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Token #{auth[:token]}"

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
    
  res = http.start do |http|
    http.request(req)
  end

  JSON.parse(res.body)
end

def get_ancestry(image_id, auth)
  uri = URI("https://#{auth[:endpoint]}/v1/images/#{image_id}/ancestry")

  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Token #{auth[:token]}"

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
    
  res = http.start do |http|
    http.request(req)
  end

  JSON.parse(res.body)
end

#repo = "postgres"
#auth = get_auth(repo)
#tags = list_tags(repo, auth)

#puts get_ancestry(tags.values.first, auth)

conn = PG.connect(dbname: 'hub', user: 'hub', host: '127.0.0.1', password: 'foo')

stmt = conn.prepare("insert_image", "insert into images (name, description, is_trusted, is_official, is_automated, star_count) values ($1, $2, $3, $4, $5, $6);")

start = 'ar'
(start..'zz').each do |q|
  i = 1
  max = 100
  loop do
    break if i > max
    results = search(q, i)
    puts "#{q}, page #{i} of #{results['num_pages']}"

    results['results'].each do |res|
      begin
        conn.exec_prepared("insert_image", [res['name'], res['description'], res['is_trusted'], res['is_official'], res['is_automated'], res['star_count']])      
      rescue PG::UniqueViolation 
      end
    end

    if i == 1
      max = results['num_pages']
    end
    i += 1
    sleep(1)
  end

  sleep(5)
  conn.exec("UPDATE last_term SET term = '#{q}'")
end
