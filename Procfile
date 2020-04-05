# RUN THIS A COUPLE OF WAYS
# IF YOU WANT TO USE ALL SERVICES LISTED BELOW
#   RUN: RAILS_ENV=development foreman start
#
# IF YOU WANT TO ONLY RUN CERTAIN SERVICES
#   USE -m FLAG AND THEN EACH SERVICE NAME YOU WANT TO RUN
#   RAILS_ENV=development foreman start -m db=1,search=1

web: bundle exec thin start -e $RAILS_ENV -p $PORT
search: bundle exec sunspot-solr run
db: redis-server
job: bundle exec sidekiq -q carrierwave -q default
