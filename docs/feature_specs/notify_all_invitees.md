#### Document info
- Tip: https://tiphiveteam.tiphive.com/cards/166596-send-notifications-to-invitees

-- START OF TIP COPY --
###
<h4 style='color: red;'> DRAFT </h4>
**Updated: 7/11/2016**

#### FOR DISCUSSION
- We need to agree on what events we will send notifications for
- We need copy for each email + subject line
  + *NOTE* we will include a Join Button on each of these with the invitation Token to the recipient
- Please see **DISCUSS** Labels below

#### PURPOSE
- So that those who have not joined yet will see things are happening on their domain

#### DESCRIPTION
##### BEHAVIOR
- When one of the following happens, all invitees to the domain should recieve a notification
- The frequency of notifications should follow the standard default
- **DISCUSS:** Do we want all of these? 
  + Someone likes my tip `someone_likes_tip: :always`,
  + Someone likes my question `someone_likes_question: :daily`,
  + Someone added a tip to a topic I follow `someone_add_tip_to_topic: :daily`,
  + Someone shares Topic with me `someone_shared_topic_with_me: :always`,
  + Someone shares Tip with me `someone_shared_tip_with_me: :always`,
  + Someone shares Question with me `someone_shared_question_with_me: :always`,
  + Someone comments on one of my tips`someone_comments_on_tip: :always`,
  + Someone is added to a group I belong to `someone_added_to_group: :always`,
  + Someone is added to a domain I belong to `someone_added_to_domain: :daily`,
  + Someone joins a domain I belong to `someone_joins_domain: :daily`,
  + Someone I follow adds a tip `someone_adds_tip: :daily`,
  + Someone I follow adds a topic `someone_adds_topic: :daily`,
  + Someone commented on tip I commented on `someone_commented_on_tip_user_commented: :always`
- `OPINION` I think the following is all we would want to send to invitees
  + Someone adds a Tip shared with everyone
  + Someone adds a Topic shared with everyone
  + Someone adds a Question shared with everyone
  + Someone joins the Domain

#### DEVELOPMENT THOUGHTS
##### API
- API might have to define these separately as Invitees do not have user records
  + This might be easier and cleaner than adding conditionals on existing notifications
- **DISCUSS:** What happens if someone joins with a different email?
  + We should already be aware of this and handling it based on invite token + email
- With each notification, we should give the Invite Token to the email recipient so they can join
- Add a Notify Invitees flag on domain, default to TRUE

##### FRONT END
- There should not be any front end work necessary for this feature

##### TESTS
- Each new notification
- Ensure that Tips shared privately do not send notifications
- Ensure that when a user joins, they no longer receive these
    * It may be that when someone joins, their invite is removed, so this may happen automatically

#### USE CASES

| AS A ... |         I WANT ...         |    SO THAT ...     |
|----------|----------------------------|--------------------|
| Admin     | invitees to be notified of events | they will want to join |
|          |                            |                    |

#### EDGE CASES


#### DIAGRAMS
```
                     ┌ ─ ─ ─ ─ ─ ─ ┐                            ┌ ─ ─ ─ ─ ─ ─ ┐                       
┌──────────────┐                           ┌──────────────┐                           ┌──────────────┐
│              │     │   Notify    │ TRUE  │   Invitee    │     │   Invitee   │ YES   │  Join Page   │
│    Event     │────▶   Invitees    ──────▶│ Notification │────▶    Clicks     ──────▶│  with Token  │
│              │     │   Setting   │       │              │     │ Email Join  │       │              │
└──────────────┘                           └──────────────┘                           └──────────────┘
                     └ ─ ─ ─ ─ ─ ─ ┘                            └ ─ ─ ─ ─ ─ ─ ┘               │       
                           │                                           │                      │       
                           │FALSE                                      │ NO                   │       
                           ▼                                           ▼                      │       
                    ┌─────────────┐                            ┌──────────────┐               │       
                    │             │                            │              │               │       
                    │ Do Not Send │                            │     END      │◀──────────────┘       
                    │             │                            │              │                       
                    └─────────────┘                            └──────────────┘                       
```

#### NEEDS FROM OTHERS
- Copy for each invitee email event - NOT REQUESTED YET