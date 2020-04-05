## Roles

#### Common Understandings
- every users carries the role of 'member'
- Owners of a resource trump Admins
- Roles do not have inherent permissions, you must create a permission and assign a role

#### Current Roles
- admin - This is active
- moderator - This needs work
- member - This is not a role you'll see in the database, its a special case

#### Future Roles
- editor

#### Creating Roles
###### Available Resources
- Roles can be applied to Domain, Topic, Tip, Question

###### Parameters for both Create and Remove
|  param  |           value           | req? |
|---------|---------------------------|------|
| user_id | id                        | yes  |
| role    | one of (admin, moderator) | yes  |

###### Payload Example
```json
  {
    'data': {
      'user_id': id of user,
      'role': 'admin' OR 'moderator'
    }
  }
```

###### Back-End
- `user.add_role :admin, domain` - creates a domain admin
- `user.add_role :admin, topic` - creates a topic admin
- `user.add_role :admin, tip` - creates a tip admin
- `user.add_role :admin, question` - creates a question admin

###### Front-End
- `POST /roles` - creates a role for domain
- `POST /topics/:topic_id/roles` - creates a role for topic
- `POST /cards/:tip_id/roles` - creates a role for tip
- `POST /questions/:question_id/roles` - creates a role for question

###### Automated Role Assignments
- Currently, when a user creates a resource, he is automatcially made an 'admin' of that resource
- There is a module `Adminify.rb` that adds this capability

#### Checking Roles
- `user.has_role? :admin, domain` - to see if the user is a domain admin

#### Removing Roles
###### Back-End
- `user.remove_role :admin, domain` - removes a domain admin
- `user.remove_role :admin, topic` - removes a topic admin
- `user.remove_role :admin, tip` - removes a tip admin
- `user.remove_role :admin, question` - removes a question admin

###### Front-End
- `POST /roles/remove` - creates a role for domain
- `POST /topics/:topic_id/roles/remove` - creates a role for topic
- `POST /cards/:tip_id/roles/remove` - creates a role for tip
- `POST /questions/:question_id/roles/remove` - creates a role for question

#### Implementing a User Interface
- To define roles, we need to list users, or roles
- Perhaps use the Domain settings form design, where the drop down allows you to find a user?

#### Future Changes
- I'd like us to convert the format to the following to create a role, instead of requiring nested endpoints

``` json
  {
    'data': {
      'type': 'roles'
      'attributes': {
        'user_id': user.id,
        'role': 'admin' OR 'moderator'
        'resource_type': 'domain', 'topic', 'tip' OR 'question',
        'resource_id': id of resource
      }
    }
  }
```

