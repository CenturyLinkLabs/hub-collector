require 'net/http'
require 'json'

def search(query, page=1)
  tries = 0
  begin
    tries += 1
    uri = URI("https://index.docker.io/v1/search?q=#{query}&page=#{page}")

    req = Net::HTTP::Get.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

  JSON.parse(res.body)
  rescue => ex
    if try <= 1
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
