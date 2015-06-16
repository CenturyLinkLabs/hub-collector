require_relative 'api'
require_relative 'db'

conn.prepare('lookup_layer_id', 'SELECT id FROM layers WHERE layer_id = $1')
conn.prepare('lookup_tags', 'SELECT repos.name||\':\'||tags.name AS name FROM tags JOIN repos ON tags.repo_id = repos.id WHERE layer_id = $1')

image = ARGV[0]
repo, tag = image.split(':')
puts "Looking up: #{repo}:#{tag}"

auth = get_auth(repo)
id = get_id_for_tag(repo, tag, auth)
layers = get_ancestry(id, auth)

layers.each do |layer_id|
  puts "Layer: #{layer_id}"
  res = conn.exec_prepared('lookup_layer_id', [layer_id])
  tags = conn.exec_prepared('lookup_tags', [res[0]['id']])

  tags.each do |tag|
    puts "  #{tag['name']}"
  end
end
