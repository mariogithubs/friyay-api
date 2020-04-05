## Database Transfer
**Documenting from MYSQL to POSTGRES and new schema**

#### Helpful links

#### For all entities
- Lookup by domain_id to place in correct Tenant
-

#### Images and attachments
- Need to upload into our S3 bucket
- Any way to do that without going through carrierwave? or is that the best option?

#### Subtopics
- Pockets become topics that have root topics as parents
- to find current assignments, we need to look for the following
  ```sql
  select * from pockets
  where id IN (
    select follower_id from follows
    where follower_type = 'Pocket'
    and followable_type = 'Hive'
    and followable_id = 2536
  );
  ```
  + Where followable_id is used to connect to the hive
  + Probably want to use a join so we can get pocket_id and hive_id
- Keep in mind that there can be multiple subtopics with the same title as long as wihin a given topic root, they are unique