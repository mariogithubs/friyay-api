#### new thoughts
- Tip.create permissions is located at the hive or domain level
  + So, tip.abilities won't show if user can create
+ Visiblity is not handled through permissions, its based on what is shared with the user
+ 


## Permissions


This document can be used to augment our understanding of permissions.

#### Common Understandings
- every users carries the role of 'member'
- if you give permission to the role of 'member' every user will have that permission
- Owners always have access to create, read, update, destroy their own resources

#### Levels of permissions
###### Domain
- At the domain level we set permissions that will become the default for all levels below
- Domain owners are the only ones by default that can set permissions
- Domain owners will be able to assign users as admins, and giving admin permissions

###### Domain Default Permissions
- Admin has all permissions always
- Creator always have all permissions

|       Permission      |  Who   |
|-----------------------|--------|
| Create Hives/SubHives | Member |
| Create a Tip          | Member |
| Edit a Tip            |        |
| Destroy a Tip         |        |
| Like a Tip            | Member |
| Comment on a Tip      | Member |
| Ask Question          | Member |
| Edit Question         |        |
| Delete Question       |        |
| Answer Question       | Member |

###### Hive
- At the hive level, each hive can have its own set of permissions
- The owner of the hive can set permissions and give others admin permissions
- ??? CAN HE? The owner can choose to give admins the right to assign other admins and change permissions
- Permissions set at the Hive level will trickle down to the tips as their default permissions settings
- ??? Should we allow the admin to determine if tips can have their own permissions? Default to no for simplicity

###### Tip - ???? MAY NOT BE IMPLEMENTED
- A the tip level, each tip can have its own set of permissions
- A tip will follow the hive permissions set unless the creator sets them differently here
- However, hive admins will have all access all the time --- is this correct? is this what we want?
- In order to give certain people permssions, you can create a permission with user_ids or groups

#### Creating Permissions
###### Available Resources
- Permissions can be placed on Domain and Hive. Tip to be confirmed

#### Params
- user_id is something special

|   attribute   |                   values                   |                     note                     |
|---------------|--------------------------------------------|----------------------------------------------|
| id            |                                            |                                              |
| action        | :create, :read, :update, :destroy, :rolify |                                              |
| subject_class | 'Tip', 'Topic', 'Question', 'Domain'       | The resource the permissions is applied to   |
| subject_role  | `roles: ['member']` or `user_ids: []`      | The roles, users, or groups given permission |
|               | or `group_ids: []`                         |                                              |
| description   |                                            | ???                                          |
| user_id       |                                            | ??? ONLY in case of a Topic                  |
| _destroy      | true                                       | true if delete nested record                 |

#### Default Permissions

| Permission           | Admin     | Owner    | Any Member    |
| -------------------- | :-------: | :------: | :-----------: |
| 'Tip-read'           | X         | X        | X             |
| 'Tip-create'         | X         | X        | X             |
| 'Tip-update'         | X         | X        |               |
| 'Tip-destroy'        | X         | X        |               |
| 'Tip-like'           | X         | X        | X             |
| 'Tip-comment'        | X         | X        | X             |
| 'Tip-rolify'         | X         | X        |               |
| 'Question-read'      | X         | X        | X             |
| 'Question-create'    | X         | X        | X             |
| 'Question-update'    | X         | X        |               |
| 'Question-destroy'   | X         | X        |               |
| 'Question-answer'    | X         | X        | X             |
| 'Question-rolify'    | X         | X        |               |
| 'Topic-read'         | X         | X        | X             |
| 'Topic-create'       | X         | X        | X             |
| 'Topic-update'       | X         | X        |               |
| 'Topic-destroy'      | X         | X        |               |
| 'Topic-rolify'       | X         | X        |               |
| 'UserProfile-read'   | X         | X        | X             |
| 'Domain-rolify'      | X         |          |               |

``` ruby
    [
      { name: 'Tip-read', action: :read, subject_class: 'Tip', subject_role: { roles: ['member'] } },
      { name: 'Tip-create', action: :create, subject_class: 'Tip', subject_role: { roles: ['member'] } },
      { name: 'Tip-update', action: :update, subject_class: 'Tip', subject_role: {} },
      { name: 'Tip-destroy', action: :destroy, subject_class: 'Tip', subject_role: {} },
      { name: 'Tip-like', action: :like, subject_class: 'Tip', subject_role: { roles: ['member'] } },
      { name: 'Tip-comment', action: :comment, subject_class: 'Tip', subject_role: { roles: ['member'] } },
      { name: 'Tip-rolify', action: :rolify, subject_class: 'Tip', subject_role: {} },
      { name: 'Question-read', action: :read, subject_class: 'Question', subject_role: { roles: ['member'] } },
      { name: 'Question-create', action: :create, subject_class: 'Question', subject_role: { roles: ['member'] } },
      { name: 'Question-update', action: :update, subject_class: 'Question', subject_role: {} },
      { name: 'Question-destroy', action: :destroy, subject_class: 'Question', subject_role: {} },
      { name: 'Question-answer', action: :answer, subject_class: 'Question', subject_role: { roles: ['member'] } },
      { name: 'Question-rolify', action: :rolify, subject_class: 'Question', subject_role: {} },
      { name: 'Topic-read', action: :read, subject_class: 'Topic', subject_role: { roles: ['member'] } },
      { name: 'Topic-create', action: :create, subject_class: 'Topic', subject_role: { roles: ['member'] } },
      { name: 'Topic-update', action: :update, subject_class: 'Topic', subject_role: {} },
      { name: 'Topic-destroy', action: :destroy, subject_class: 'Topic', subject_role: {} },
      { name: 'Topic-rolify', action: :rolify, subject_class: 'Topic', subject_role: {} },
      { name: 'UserProfile-read', action: :read, subject_class: 'UserProfile', subject_role: { roles: ['member'] } },
      { name: 'Domain-rolify', action: :rolify, subject_class: 'Domain', subject_role: {} }
    ]
```

#### Createing 