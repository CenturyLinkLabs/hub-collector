require_relative 'api'
require_relative 'db'

select_repos = 'SELECT id, name FROM repos WHERE marked = true'
unmark_repo = 'UPDATE repos SET marked = false WHERE id = $1'
delete_repo = 'DELETE FROM repos WHERE id = $1'
select_tags = 'SELECT id FROM tags WHERE repo_id = $1'
delete_tag_layer = 'DELETE FROM tag_layers WHERE tag_id = $1'
delete_tag = 'DELETE FROM tags WHERE id = $1'

conn.prepare('unmark_repo', unmark_repo)
conn.prepare('delete_repo', delete_repo)
conn.prepare('select_tags', select_tags)
conn.prepare('delete_tag_layer', delete_tag_layer)
conn.prepare('delete_tag', delete_tag)

loop do
  res = conn.exec(select_repos)
  res.each do |repo|
    repo_id = repo['id']
    repo_name = repo['name']
    begin
      get_auth(repo_name)
      conn.exec_prepared('unmark_repo', [repo_id])
      puts "#{repo_name}: unmarked"
    rescue NotFoundError
      begin
        tags = conn.exec_prepared('select_tags', [repo_id])

        tags.each do |tag|
          tag_id = tag['id']
          conn.exec_prepared('delete_tag_layer', [tag_id])
          conn.exec_prepared('delete_tag', [tag_id])
        end

        conn.exec_prepared('delete_repo', [repo_id])
        puts "#{repo_name}: deleted"
      rescue => ex
        puts "Error: #{ex}"
      end
    rescue => ex
      puts "Error: #{ex}"
    end
  end

  sleep(60*60)
end
