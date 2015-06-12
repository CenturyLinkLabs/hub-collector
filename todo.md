* Backup pg db
* populate remaining tag+layer entries with `#get_ancestry`


Repos
  tags
    layers


ubuntu:latest -> acd345
- adc456 < ^
- ythasdf
- gthasdf

## Potential Dashboard stats

x * Number of automated / Number of not-automated (and %)
x * list official repos sorted by star count or some shit.
x * Repos with highest star count, non-official
x * Repos grouped by number of tags DESC


* Mean, Range, Median, Mode of tags per repo
* Organizations with the most repos -> repos -> tag count
* Most popular tag names (across repos)
  * select name, count(name) as name_count from tags group by name order by name_count desc
