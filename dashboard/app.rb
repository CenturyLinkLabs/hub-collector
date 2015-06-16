require 'sinatra'
require 'haml'
require 'pg'
require_relative '../api'

set :bind, '0.0.0.0'

$conn = PG.connect(dbname: 'hub', user: 'hub', password: 'hub', host: '127.0.0.1')

$conn.prepare('lookup_layer_id', 'SELECT id FROM layers WHERE layer_id = $1')
$conn.prepare('lookup_tags', 'SELECT repos.name||\':\'||tags.name AS name FROM tags JOIN repos ON tags.repo_id = repos.id WHERE layer_id = $1')

get '/' do
  haml :index
end

get '/analyze' do
  expected = params[:expected] && params[:expected].split("\r\n")
  @results = params[:image] ? analyze(params[:image], (expected || [])) : {layers: {}, unmatched_tags: []}
  haml :analyze
end

def analyze(image, expected)
  repo, tag = image.split(':')

  auth = get_auth(repo)
  id = get_id_for_tag(repo, tag, auth)
  layers = get_ancestry(id, auth)

  layer_results = {}
  layers.reverse.each do |layer_id|
    res = $conn.exec_prepared('lookup_layer_id', [layer_id])
    tags = $conn.exec_prepared('lookup_tags', [res[0]['id']])

    layer_results[layer_id] = tags.map do |h| 
      h['match'] = expected.include? h['name']
      expected.delete(h['name'])
      h
    end
  end
  { 
    layers: layer_results || {},
    unmatched_tags: expected || []
  }
end

def total_official
  res = $conn.exec('SELECT count(*) FROM repos where is_official')
  res[0]['count'].to_i
end

def total_automated
  res = $conn.exec('SELECT count(*) FROM repos where is_automated')
  res[0]['count'].to_i
end

def total_tags
  res = $conn.exec('SELECT count(*) FROM tags')
  res[0]['count'].to_i
end

def total_repos
  res = $conn.exec('SELECT count(*) FROM repos')
  res[0]['count'].to_i
end

def repos_with_tag_count
  $conn.exec('SELECT repos.name, repos.is_official, count(tags.id) as tag_count FROM repos, tags WHERE repos.id = tags.repo_id group by repos.id ORDER BY tag_count DESC LIMIT 100')
end

def repos_with_tag_count_unlimited
  $conn.exec('SELECT repos.name, repos.is_official, count(tags.id) as tag_count FROM repos, tags WHERE repos.id = tags.repo_id group by repos.id ORDER BY tag_count DESC')
end

def tags_grouped_by_name
  $conn.exec("select name, count(name) as name_count from tags group by name order by name_count desc LIMIT 100")
end

def repos_by_org
  $conn.exec("select split_part(name, '/', 1) as org, count(split_part(name, '/', 2)) as repo_count from repos group by org order by repo_count desc LIMIT 100")
end

def median_tags_per_repo
  length = repos_with_tag_count_unlimited.count
  index = length / 2
  repos_with_tag_count_unlimited[index]["tag_count"]
end

def non_official_repos_by_star
  $conn.exec('SELECT name, star_count FROM repos WHERE NOT is_official order by star_count DESC limit 100')
end

def official_repos_by_star
  $conn.exec('SELECT name, star_count FROM repos WHERE is_official order by star_count DESC limit 100')
end

def total_layers
  res = $conn.exec('SELECT count(*) FROM layers')
  res[0]['count'].to_i
end

def most_referenced_layers
  res = $conn.exec('SELECT layers.layer_id, string_agg(repos.name||\':\'||tags.name, \'|\') AS images, layers.count AS count FROM ( SELECT tags.layer_id, COUNT(tag_layers.layer_id) AS count FROM ( SELECT DISTINCT tags.layer_id FROM TAGS) AS tags JOIN tag_layers ON tags.layer_id = tag_layers.layer_id GROUP BY tags.layer_id ORDER BY count DESC LIMIT 100) AS layers JOIN tags ON layers.layer_id = tags.layer_id JOIN repos ON tags.repo_id = repos.id GROUP BY layers.layer_id, layers.count ORDER BY layers.count desc;')

  res.map do |r|
    {
      'layer_id' => r['layer_id'],
      'images' => r['images'].split('|').reject { |x| x.include?('/') }.join(', '),
      'count' => r['count']
    }
  end
end

def badass_number(num)
  num.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
end

def badass_percentage(num, den)
  sprintf("%.2f%%", (num.to_f / den * 100))
end

def badass_bool(flag)
  flag == "f" ? "FALSE" : "TRUE"
end

def badass_id(id)
  id[0..11]
end

def badass_ratio(num, den)
  sprintf("%.2f", (num.to_f / den))
end
