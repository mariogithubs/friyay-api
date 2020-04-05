## Questions

## Gems in use
*list of gems that tips use*

## TipHive Libraries in use
*list of modules that Question includes*
- 

## Definitions/Rules
- 

## Use
- 

## JSONAPI Schema
#### Single Record Show
```json
  {
    "data": {
      "id": "27",
      "type": "tips",
      "attributes": {
        "title": "Test Title 11",
        "color_index": 2
      },
      "relationships": {
        "domain": {
          "data": {
            "id": 1,
            "name": "Domain 1"
          }
        },
        "creator": {
          "data": {
            "id": 1,
            "name": "Anthony Lassiter",
            "url": ""
          }
        },
        "topics": {
          "data": [
            {
              "id": 1,
              "title": "Repudiandae Sunt",
              "url": "http://api.api.dev/v2/topics/1-repudiandae-sunt"
            }
          ]
        },
        "subtopics": {
          "data": []
        },
        "user_followers": {
          "data": []
        }
      }
    }
  }
```

#### Single Record Create
```json
  {
    data: {
      "type": 'tip',
      "attributes": {
        "title": "Tip Title",
        "body": "Tip content as a long paragraph",
      },
      "relationships": {
        "subtopics": {
          "data": [{ "id": 1 }]
        },
        "user_followers": {
          "data": [{ "id": 1 }, { "id": 2 }]
        },
      }
    }
  }
```


## Migration from 15.2

## Future Ideas


```ruby
create_table "questions", force: :cascade do |t|
  t.text     "name",                  limit: 65535
  t.integer  "user_id",               limit: 4
  t.datetime "created_at"
  t.datetime "updated_at"
  # NOT for 15.4.1 t.boolean  "library",               limit: 1
  t.time     "sent_at"
  t.integer  "comments_count",        limit: 4,     default: 0
  t.string   "sharing_type",          limit: 255,   default: "all_friends"
  t.integer  "cached_votes_total",    limit: 4,     default: 0
  t.integer  "cached_votes_score",    limit: 4,     default: 0
  t.integer  "cached_votes_up",       limit: 4,     default: 0
  t.integer  "cached_votes_down",     limit: 4,     default: 0
  t.integer  "cached_weighted_score", limit: 4,     default: 0
  t.boolean  "is_public",             limit: 1,     default: false
  t.boolean  "is_private",            limit: 1,     default: false
  t.boolean  "shared_all_friends",    limit: 1,     default: false
  t.boolean  "shared_select_friends", limit: 1,     default: false
  t.integer  "domain_id",             limit: 4
  t.string   "access_key",            limit: 255
  t.string   "color",                 limit: 255
  t.integer  "pictures_count",        limit: 4
  t.boolean  "anonymously",           limit: 1,     default: false
end

add_index "questions", ["access_key"], name: "index_questions_on_access_key", using: :btree
add_index "questions", ["cached_votes_down"], name: "index_questions_on_cached_votes_down", using: :btree
add_index "questions", ["cached_votes_score"], name: "index_questions_on_cached_votes_score", using: :btree
add_index "questions", ["cached_votes_total"], name: "index_questions_on_cached_votes_total", using: :btree
add_index "questions", ["cached_votes_up"], name: "index_questions_on_cached_votes_up", using: :btree
add_index "questions", ["cached_weighted_score"], name: "index_questions_on_cached_weighted_score", using: :btree
add_index "questions", ["domain_id"], name: "index_questions_on_domain_id", using: :btree
add_index "questions", ["sharing_type"], name: "index_questions_on_sharing_type", using: :btree
add_index "questions", ["user_id"], name: "index_questions_on_user_id", using: :btree
```
