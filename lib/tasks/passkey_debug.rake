namespace :passkeys do
  desc "Debug passkey identifiers and show detailed information"
  task debug: :environment do
    puts "🔍 Passkey Debug Information"
    puts "=" * 50

    User.joins(:passkeys).distinct.each do |user|
      puts "\n👤 User: #{user.email} (ID: #{user.id})"
      puts "  📊 Total passkeys: #{user.passkeys.count}"

      user.passkeys.each_with_index do |passkey, i|
        puts "\n  🔑 Passkey #{i + 1}:"
        puts "    - ID: #{passkey.id}"
        puts "    - Label: #{passkey.label}"
        puts "    - Created: #{passkey.created_at}"
        puts "    - Last Used: #{passkey.last_used_at}"
        puts "    - Sign Count: #{passkey.sign_count}"
        puts "    - Identifier: #{passkey.identifier}"
        puts "    - Identifier Length: #{passkey.identifier.length}"

        # Base64URLデコードを試行
        begin
          decoded = Base64.urlsafe_decode64(passkey.identifier)
          hex_value = decoded.unpack1("H*")
          puts "    - Decoded Hex: #{hex_value}"
          puts "    - Decoded Length: #{decoded.length} bytes"
        rescue => e
          puts "    - Decode Error: #{e.message}"
        end

        # 公開鍵の情報
        puts "    - Public Key Length: #{passkey.public_key&.length || 'N/A'}"
        puts "    - Public Key Present: #{passkey.public_key.present? ? '✅' : '❌'}"
      end
    end

    puts "\n" + "=" * 50
    puts "🔍 Total Statistics:"
    puts "  - Total Users with Passkeys: #{User.joins(:passkeys).distinct.count}"
    puts "  - Total Passkeys: #{Passkey.count}"
  end

  desc "Clear all passkeys for a specific user (dangerous)"
  task :clear_user_passkeys, [ :email ] => :environment do |t, args|
    if args[:email].blank?
      puts "Usage: rails passkeys:clear_user_passkeys[user@example.com]"
      exit 1
    end

    user = User.find_by(email: args[:email])
    if user.nil?
      puts "❌ User not found: #{args[:email]}"
      exit 1
    end

    passkey_count = user.passkeys.count
    print "⚠️  Are you sure you want to delete #{passkey_count} passkeys for #{user.email}? (yes/NO): "
    confirmation = STDIN.gets.chomp

    if confirmation.downcase == "yes"
      deleted = user.passkeys.destroy_all.count
      puts "✅ Deleted #{deleted} passkeys for #{user.email}"
    else
      puts "❌ Operation cancelled"
    end
  end

  desc "Show current authentication identifier from logs"
  task show_current_auth: :environment do
    puts "🔍 Current Authentication Analysis"
    puts "Check your Rails logs for the most recent authentication attempt"
    puts "Look for lines containing:"
    puts "  - 'Raw ID hex: [hex_value]'"
    puts "  - 'Decoded hex: [hex_value]'"
    puts "\nIf the hex values don't match, you need to register a new passkey."
    puts "\nTo register a new passkey:"
    puts "1. Go to /passkeys"
    puts "2. Click 'パスキーを登録'"
    puts "3. Complete the registration process"
  end
end
