class UserSmallSerializer
  include FastJsonapi::ObjectSerializer
  attributes :first_name, :last_name, :name, :username

end
