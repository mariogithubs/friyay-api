## Topics
*also known as hives and subtopics*

## Definitions/Rules
- a user may add tips to hives regardless of if they follow the hive


## Use
- To share a topic with someone
- !!!!! **THIS HAS CHANGED. SHARING ONLY NOTIFIES NOW**
  + POST `v2/topics/:id/share_with_users` and deliver a payload with user_followers in the following structure

        ```json
          {
              "data":{
                  "id": :id_of_topic,
                  "type": "topics",
                  "relationships": {
                      "user_followers": {
                          "data": [
                              { "id": 1, "type": "users" },
                              { "id": 2, "type": "users" }
                          ]
                      }
                  }
              }
          }
        ```
- Only a creator or an admin can edit the title once created
- An admin should have the ability to change the creator
- We should not automatically share hives, we can notify, but not autoshare

#### API Requests
###### Index
- api.tiphive.com/v2/hives

###### Show
- GET /v2/topics/1

```json
    {
      "id": "1",
      "type": "topics",
      "attributes": {
        "title": "Test Topic",
        "description": null,
        "slug": "1-test-topic",
        "created_at": "2015-12-21T14:43:04.857Z"
      },
      "relationships": {
        "parent": {
          "data": null
        },
        "children": {
          "data": [
            {
              "id": "10",
              "type": "topics"
            },
            {
              "id": "11",
              "type": "topics"
            }
          ]
        },
        "topic_preferences": {
          "data": [
            {
              "id": 1,
              "type": "topic_preferences",
              "background_color_index": 3,
              "background_image": "",
              "is_on_profile": true,
              "is_private": true,
              "is_public": false,
              "shared_all_friends": true
            }
          ]
        },
        "share_settings": {
          "data": [
            {
              "id": 1,
              "sharing_object_id": 13,
              "sharing_object_type": "User",
              "sharing_object_name": "Editor Account",
              "shareable_object_avatar": null
            }
          ]
        },
        "tip_followers": {
          "data": [
            {
              "id": "4",
              "type": "tips"
            },
            {
              "id": "9",
              "type": "tips"
            }
          ]
        },
        "question_followers": {
          "data": [
            {
              "id": "1",
              "type": "questions"
            }
          ]
        },
        "user_followers": {
          "data": [
            {
              "id": "3",
              "type": "users"
            },
            {
              "id": "2",
              "type": "users"
            }
          ]
        },
        "group_followers": {
          "data": []
        },
        "list_followers": {
          "data": []
        }
      }
    }
```

**With Tips(Default)**

- api.tiphive.com/v2/hives/1
  + returns topic 1
  + with topic_preferences for current_user
  + with tips

**With Questions**

- api.tiphive.com/v2/hives/1?include=questions
  + returns topic 1
  + with topic_preferences for current_user
  + with questions

#### Hive
  + A topic instance that has a unique title for a given domain
    * If no parent_id, validate uniqueness of title constrained within same domain_id
  + A hive is always public, we don't need as setting for this
  + The tips in a hive may or may not be public

#### Subtopic
  + A topic instance that always has a parent
  + Should have a unique name within a parent
    * If parent_id, validate uniqueness of title constrained within same parent_id
  + A subtopic cannot be deleted if it contains tips, the tips must be moved first
    * Enhancement idea - make it easy to move tips to other subtopics
