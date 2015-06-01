CREATE TABLE layers (
  id serial PRIMARY KEY,
  layer_id char(64) UNIQUE,
  parent_id int,
  updated_at timestamp,
  CONSTRAINT fk1_layers FOREIGN KEY (parent_id) REFERENCES layers (id)
);

CREATE TABLE repos (
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
  repo_id int,
  name varchar(1024),
  layer_id int,
  updated_at timestamp,
  CONSTRAINT fk1_tags FOREIGN KEY (repo_id) REFERENCES repos (id),
  CONSTRAINT fk2_tags FOREIGN KEY (layer_id) REFERENCES layers (id),
  CONSTRAINT u_repo_id_name UNIQUE (repo_id, name)
);

CREATE TABLE tag_layers (
  tag_id int,
  layer_id int,
  CONSTRAINT fk1_tag_layers FOREIGN KEY (tag_id) REFERENCES tags (id),
  CONSTRAINT fk2_tag_layers FOREIGN KEY (layer_id) REFERENCES layers (id),
  CONSTRAINT u_tag_id_layer_id UNIQUE (tag_id, layer_id)
);
