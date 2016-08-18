CREATE TABLE tags (
  tag_id serial NOT NULL,
  tag text NOT NULL,
  create_date timestamp not null default (now() at time zone 'utc'),
  CONSTRAINT pk_tags PRIMARY KEY (tag_id)
) WITH (
OIDS=FALSE
);
--;;
insert into tags (tag) VALUES('supper');
--;;
insert into tags (tag) VALUES('howto');