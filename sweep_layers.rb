require_relative 'api'
require_relative 'db'

select_orphaned_layers = 'SELECT layers.id FROM layers'\
  ' LEFT JOIN tag_layers ON layers.id = tag_layers.layer_id'\
  ' LEFT JOIN tags ON layers.id = tags.layer_id'\
  ' LEFT JOIN layers AS p ON layers.id = p.parent_id'\
  ' WHERE tag_layers.layer_id IS NULL'\
  ' AND tags.layer_id IS NULL'\
  ' AND p.parent_id IS NULL'

conn.prepare('delete_layer', 'DELETE FROM layers WHERE id = $1')

loop do
  puts "start sweep: #{Time.now}"
  layers = conn.exec(select_orphaned_layers)

  deleted_layers = 0
  layers.each do |layer|
    layer_id = layer['id']
    begin
      conn.exec_prepared('delete_layer', [layer_id])
      deleted_layers += 1
    rescue => ex
      puts "Error: #{ex}"
    end
  end

  puts "deleted #{deleted_layers} layers"
end
