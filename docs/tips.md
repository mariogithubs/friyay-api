## Tips

### API USE
#### Headers for requests needing authorization
- Authorization
  + Valid Values
    * A user's Authentication token retrieved after signing in
  + Example
    * `Authorization: Bearer Yhkeis93839jfjHkdjk...`
- X-Tenant-Name
  + Valid Values
    * public
    * an existing TipHive domain name (currently case sensitive)
  + Example
    * `X-Tenant_Name: TipHiveTeam`
- Content-Type
  + Valid Values
    * application/vnd.api+json
  + Example
    * `Content-Type: application/vnd.api+json`


---
#### Pagination
---
- Tips are paginated by default. the default size is 25 tips
- You can get all tips without pagination if you pass ?pager=false as a param
- You can change the defaults by passing ?page[number]=1&page[size]=10

---
###### GET /tips
---
- `GET /tips`
    + returns: a list of tips the user is following
```json
{
  "data": [
    {
      "id": "2",
      "type": "tips",
      "attributes": {
        "title": "Test Title",
        "body": "[\"Et qui aut dolores vel est. Recusandae molestiae ullam amet aut quia. Incidunt mollitia voluptatem et sequi officiis. \"]",
        "color_index": 2
      },
      "relationships": {
        "user": {
          "data": {
            "id": "2",
            "type": "users"
          }
        },
        "topics": {
          "data": [
            {
              "id": "2",
              "type": "topics"
            }
          ]
        },
        "subtopics": {
          "data": []
        },
        "comment_threads": {
          "data": []
        },
        "user_followers": {
          "data": [
            {
              "id": "2",
              "type": "users"
            }
          ]
        }
      }
    }
    // ...
  ] // end data
}
```
  
- `GET /tips?include=user`
    + returns: tips as above AND user information
```json
{
  "data": [
    {
      "id": "2",
      "type": "tips",
      "attributes": { ... }, 
      "relationships": { ... }
    }
    // ...
  ],
  "included": [
    {
      "id": "2",
      "type": "users",
      "attributes": {
        "email": "anthonylassiter@gmail.com",
        "first_name": "Anthony2",
        "last_name": "LastNamee"
      }
    }
  ]
}
```

| Parameter | Optional? | Values | Description
|-------|:------:|-----|-----|
| include | yes | user | includes extra fields for user |

---
###### GET /cards/:id - Get a single tip
---
- examples:
  + GET /cards/1
    * returns: a tip with id of 1
  + GET /cards/1?include=user
    * returns: tip #1 with its user included

---
###### POST /tips - Create a new tip
---
- examples
    + POST /tips
    + *data payload*
```json
{
    "data":{
        "type": "tip",
        "attributes": {
            "title": "Test Title with root"
        },
        "relationships": {
            "subtopics": {
                "data": [{ "id": "7", "type": "topics" }]
            },
            "user_followers": {
                "data": [{ "id": "2", "type": "users" }]
            }
        }
    }
}
```

## Gems in use
*list of gems that tips use*

## TipHive Libraries in use
*list of modules that Tip includes*

- Slugger - handles slugs
- Connectable - handles connecting objects
    + `not available` Connectable.connect(user, object) - two way connection
    + `not available` Connectable.assign(tip, topic) - one way connection
    + `not available` Connectable.follow(user, object) - one way connection

## Definitions/Rules
- A tip should only follow one or more subtopics, it should never follow a top level topic (Hive)
- The Hive is inferred from the subtopic relationship
- Public: Available to the outside public
- Private: NO ONE BUT THE CREATOR CAN SEE IT


## Migration from 15.2
- Can we delete current tips marked as deleted? We will have a backup if needed

## Future Ideas
- Theme instead of color
    + Allows us to set font, color, layouts per tip

## Inheritance Models
- Inherited Models set up special sets of HStore settings
- May also set up specialty real attributes if indexed
- Allows for special rules to be followed on display

#### LegacyTip
- This model represents a tip from 15.2
- used to allow previous attributes

#### PersonTip
- Future Tip Type
- Rules
  + No draft - auto publish
  + No expiration
- Presented as a contact entry

#### PlaceTip
- Future Tip Type
- Rules
  + Should have a location

#### ThingTip
- Future Tip Type
- May namespace
  + Thing::Movie
  + Thing::Recipe
  + Thing::Review
- Rules
  + Doesn't have a location

## Tip Schema Status

#### Transfer from MYSQL to POSTGRES
- do not migrate sharing_type, shared_all_friends, shared_select_friends

#### SCHEMA temporary

```ruby
create_table "tips", force: :cascade do |t|
  # Attributes currently assigned to 15.4
  t.string   "title",                 limit: 255
  t.text     "description",           limit: 65535
  t.integer  "user_id",               limit: 4
  t.integer  "domain_id",             limit: 4
  t.datetime "created_at"
  t.datetime "updated_at"
  t.string   "slug",                  limit: 255
  t.string   "color",                 limit: 255
  t.string   "access_key",            limit: 255
  t.boolean  "is_public",             limit: 1,     default: false
  t.boolean  "is_private",            limit: 1,     default: false

  # Attributes not added
  t.integer  "question_id",           limit: 4
  # properties per tip type

  # attributes to maybe add in Alpha? or do we create a maps table?
  t.string   "address",               limit: 255
  t.string   "latitude",              limit: 255
  t.string   "longitude",             limit: 255
  t.string   "location",              limit: 255

  # Statistics for all
  t.integer  "pictures_count",        limit: 4,     default: 0
  t.integer  "cached_votes_total",    limit: 4,     default: 0
  t.integer  "cached_votes_score",    limit: 4,     default: 0
  t.integer  "cached_votes_up",       limit: 4,     default: 0
  t.integer  "cached_votes_down",     limit: 4,     default: 0
  t.integer  "cached_weighted_score", limit: 4,     default: 0
  t.integer  "comments_count",        limit: 4,     default: 0
  t.integer  "links_count",           limit: 4,     default: 0

  # LegacyTip properties from 15.2
  t.string   "sharing_type",          limit: 255,   default: "select_friends"
  t.boolean  "shared_all_friends",    limit: 1,     default: false
  t.boolean  "shared_select_friends", limit: 1,     default: false

  # when we want to allow draft and publish options on a tip
  t.datetime "published_at"

  # Attributes we no longer need
  X t.datetime "deleted_at"
  X t.integer  "destroyer_id",          limit: 4
  X t.integer  "draft",                 limit: 4
end
```
