* Backup pg db
* Grab all the tags for each image
** Select a batch of images (i.e. dont select them all at once)
** for each image authenticate, then call `#list_tags`
** insert tags into the db
*** insert tag record, then layer record, the join record for each tag
** populate remaining tag+layer entries with `#get_ancestry`
* Schema changes
** images -> repos
** audit primary keys
** layers should have an auto-increment key??
** Uniqueness constraint on image_id+name in tags table
** Uniqueness constraint on tag_id+layer_id in tag_layers table
** add db indexes

{'latest':'abc123', '12.4':'abc123'}

Repos
  tags
    layers


ubuntu:latest -> acd345
- adc456 < ^
- ythasdf
- gthasdf
