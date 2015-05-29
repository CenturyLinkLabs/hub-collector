CREATE TABLE layers (
  layer_id varchar(64) PRIMARY KEY,
  parent_id varchar(64),
  CONSTRAINT fk1_layers FOREIGN KEY (parent_id) REFERENCES layers (layer_id)
);

CREATE TABLE images (
  id serial PRIMARY KEY,
  name varchar(1024) UNIQUE,
  description text,
  is_trusted boolean,
  is_official boolean,
  is_automated boolean,
  star_count int
);

CREATE TABLE last_term (
  term varchar(2)
);

INSERT INTO last_term (term) values('__');

CREATE TABLE tags (
  id serial PRIMARY KEY,
  image_id int,
  name varchar(1024),
  CONSTRAINT fk1_tags FOREIGN KEY (image_id) REFERENCES images (id)
);

CREATE TABLE tag_layers (
  tag_layer_id serial PRIMARY KEY,
  tag_id int,
  layer_id varchar(64),
  CONSTRAINT fk1_tag_layers FOREIGN KEY (tag_id) REFERENCES tags (id),
  CONSTRAINT fk2_tag_layers FOREIGN KEY (layer_id) REFERENCES layers (layer_id)
);
