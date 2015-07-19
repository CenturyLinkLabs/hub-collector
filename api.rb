require 'net/http'
require 'json'

def search(query, page=1, num=25)
  retry_once do
    uri = URI("https://index.docker.io/v1/search?q=#{query}&page=#{page}&n=#{num}")

    req = Net::HTTP::Get.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

    check_status(res)
    JSON.parse(res.body)
  end
end


def get_auth(repo)
  retry_once do
    uri = URI("https://index.docker.io/v1/repositories/#{repo}/images")

    req = Net::HTTP::Get.new(uri)
    req['X-Docker-Token'] = true

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

    check_status(res)

    {
      token: res['X-Docker-Token'],
      endpoint: res['X-Docker-Endpoints']
    }
  end
end

def list_tags(repo, auth)
  retry_once do
    uri = URI("https://#{auth[:endpoint]}/v1/repositories/#{repo}/tags")

    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Token #{auth[:token]}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 300

    res = http.start do |http|
      http.request(req)
    end

    check_status(res)
    JSON.parse(res.body)
  end
end

def get_ancestry(image_id, auth)
  retry_once do
    uri = URI("https://#{auth[:endpoint]}/v1/images/#{image_id}/ancestry")

    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Token #{auth[:token]}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

    check_status(res)
    JSON.parse(res.body)
  end
end

def get_id_for_tag(repo, tag, auth)
  retry_once do
    uri = URI("https://#{auth[:endpoint]}/v1/repositories/#{repo}/tags/#{tag}")

    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Token #{auth[:token]}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

    check_status(res)
    #res.body.gsub(/^\"/, '').gsub(/$\"/,'')
    res.body[1..-2]
  end
end

def get_dockerfile(repo)
  retry_once do
    uri = URI("https://registry.hub.docker.com/u/#{repo}/dockerfile/raw")

    req = Net::HTTP::Get.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      http.request(req)
    end

    check_status(res)
    res.body
  end
end

def retry_once
  retryable = true
  begin
    yield
  rescue ServerError => ex
    if retryable
      retryable = false
      puts "RETRY: #{ex}"
      sleep(5)
      retry
    end
    raise ex
  end
end

class NotFoundError < StandardError; end
class ServerError < StandardError; end

def check_status(response)
  case response
  when Net::HTTPSuccess
    true
  when Net::HTTPNotFound
    raise NotFoundError, "#{response.code} - #{response.uri}"
  else
    raise ServerError, "#{response.code} - #{response.uri}"
  end
end
