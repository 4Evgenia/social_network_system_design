Table users {
  id uuid [primary key, default: `uuidv7()`]
  username varchar(100) [not null, unique]
  email varchar(256) [not null, unique]
  bio varchar(2000)
  followers_count integer [not null, default: 0, note: 'денормализовано, т.к. до 1 млн. подписчиков']
  following_count integer [not null, default: 0, note: 'денормализовано для симметрии']
  created_at timestamptz [not null, default: `now()`]
}

Table subscriptions {
  follower_id  uuid [not null, ref: > users.id]
  following_id uuid [not null, ref: > users.id]
  created_at   timestamptz [not null, default: `now()`]

  indexes {
    (follower_id, following_id) [pk]
    (following_id, follower_id) [name: 'idx_subscriptions_following']
  }
}

Table countries {
  code char(2) [pk, note: 'ISO 3166-1 alpha-2']
  name varchar(100) [not null, unique]
}

Table places {
  id uuid [pk, default: `uuidv7()`]
  country_code char(2) [not null, ref: > countries.code]
  name varchar(200) [not null]
  latitude float8 [not null]
  longitude float8 [not null]
  created_at   timestamptz [not null, default: `now()`]

  indexes {
    name [name: 'idx_places_name_trgm', note: 'GIN + pg_trgm по lower(name): поиск по подстроке без учета регистра']
  }
}

Table posts {
  id uuid [pk, default: `uuidv7()`]
  description varchar(10000)
  place_id uuid [not null,  ref: > places.id]
  author_id uuid [not null,  ref: > users.id]
  likes_count    integer [not null, default: 0, note: 'денормализовано, обновляется в транзакции с лайком']
  comments_count integer [not null, default: 0, note: 'денормализовано, обновляется в транзакции с комментарием']
  created_at   timestamptz [not null, default: `now()`]

  indexes {
    (author_id, created_at) [name: 'idx_posts_author_created', note: 'лента автора и лента по подпискам']
    (place_id, created_at)  [name: 'idx_posts_place_created', note: 'лента места']
  }
}

Table photos {
  id uuid [pk, default: `uuidv7()`]
  author_id uuid [not null, ref: > users.id, note: 'владелец файла, нужен до прикрепления к публикации']
  post_id uuid [null, ref: > posts.id, note: 'NULL, пока фото не прикреплено к публикации']
  position    smallint [note: 'порядок фото внутри публикации']
  storage_key varchar(255) [not null, unique, note: 'ключ объекта в хранилище, без домена и схемы']
  created_at  timestamptz [not null, default: `now()`]

  indexes {
    (post_id, position) [name: 'idx_photos_post_position', note: 'фото публикации в заданном порядке']
    created_at [name: 'idx_photos_orphans', note: 'частичный индекс WHERE post_id IS NULL - для удаления неприкрепленных по таймеру']
  }
}

Table likes {
  post_id uuid [not null, ref: > posts.id]
  user_id uuid [not null, ref: > users.id]
  created_at   timestamptz [not null, default: `now()`]

  indexes {
    (post_id, user_id) [pk]
  }
}

Table comments {
  id uuid [pk, default: `uuidv7()`]
  post_id uuid [not null, ref: > posts.id]
  author_id uuid [not null, ref: > users.id]
  text varchar(2000) [not null]
  created_at   timestamptz [not null, default: `now()`]

  indexes {
    (post_id, created_at)  [name: 'idx_comments_post_created']
  }
}