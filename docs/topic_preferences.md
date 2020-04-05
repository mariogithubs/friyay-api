## TopicPreferences
*User specific settings for a topic*

## Definitions
- A topic can have many preferences
- A topic_preference belongs_to a topic and belongs_to a user
- A profile stores settings unique to individuals

#### background_color
  + Stored as an integer, the front end will decide the color
  + from old site, here is index for use in upgrade migration
    * 1: liteorange
    * 2: orange
    * 3: purple
    * 4: litepurple
    * 5: green
    * 6: liteblue
    * 7: blue


## Use
- When creating a new Topic, build a new TopicProfile for the creating user
- nest the form for TopicProfile in Topic
- Save the topic profile fields when saving topic
- we only need to create if someone edits a topic settings
  + Topic titles are set and cannot be edited except by creator and admin
  + When a non-creator edits, they get image and color settings and we create a new topic profile for the topic they are editing

