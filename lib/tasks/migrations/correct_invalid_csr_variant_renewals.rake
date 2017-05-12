require File.join(Rails.root, "app", "data_migrations", "correct_invalid_csr_variant_renewals")

# RAILS_ENV=production bundle exec rake migrations:correct_invalid_csr_variant_renewals  hbx_ids="609882,609228,609306", renewal_date = "1/1/2017"
namespace :migrations do
  desc "correct_invalid_csr_variant_renewals"
  CorrectInvalidCsrVariantRenewals.define_task :correct_invalid_csr_variant_renewals => :environment
end