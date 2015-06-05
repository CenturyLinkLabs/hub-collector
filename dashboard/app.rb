require 'sinatra'
require 'haml'
require 'pg'

set :bind, '0.0.0.0'

$conn = PG.connect(dbname: 'hub', user: 'hub', password: 'foo', host: '127.0.0.1')

get '/' do
  haml :index
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

def badass_number(num)
  num.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
end

def badass_percentage(num, den)
  sprintf("%.2f%%", (num.to_f / den * 100))
end

def badass_bool(flag)
  flag == "f" ? "FALSE" : "TRUE"
end

def badass_ratio(num, den)
  sprintf("%.2f", (num.to_f / den))
end
