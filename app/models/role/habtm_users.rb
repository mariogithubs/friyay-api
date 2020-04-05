# -*- SkipSchemaAnnotations

# rubocop:disable Style/ClassAndModuleCamelCase
class Habtm_Users < Role::HABTM_Users
  belongs_to :user
  belongs_to :role
end
# rubocop:enable Style/ClassAndModuleCamelCase
