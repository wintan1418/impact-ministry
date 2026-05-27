# Idempotent seed — safe to run repeatedly in every environment.
# See `db:seed` task.

# -----------------------------------------------------------
# Bootstrap admin (override email/password via ENV in prod).
# -----------------------------------------------------------
admin_email = ENV.fetch("BOOTSTRAP_ADMIN_EMAIL", "admin@impactministry.local")
admin_pw    = ENV.fetch("BOOTSTRAP_ADMIN_PASSWORD", "change-me-immediately")

admin = User.find_or_initialize_by(email_address: admin_email)
if admin.new_record?
  admin.password = admin_pw
  admin.name = "IMPACT Admin"
  admin.role = "admin"
  admin.confirmed_at = Time.current
  admin.save!
  puts "Seeded admin: #{admin.email_address} (password from BOOTSTRAP_ADMIN_PASSWORD or default — rotate in prod)"
else
  puts "Admin user already present: #{admin.email_address}"
end
