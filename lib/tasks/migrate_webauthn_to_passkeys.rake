# lib/tasks/migrate_webauthn_to_passkeys.rake
namespace :passkeys do
  desc "Migrate existing WebAuthn credentials to Passkeys"
  task migrate: :environment do
    puts "Starting migration from WebAuthn credentials to Passkeys..."

    migrated_count = 0
    error_count = 0

    WebauthnCredential.includes(:user).find_each do |credential|
      begin
        # ✅ Passkeyモデルの正規化メソッドを使用
        normalized_identifier = Passkey.normalize_identifier(credential.external_id)
        Rails.logger.info "Normalizing identifier: #{credential.external_id} -> #{normalized_identifier}"

        # 既に移行済みかチェック
        if Passkey.exists?(identifier: normalized_identifier)
          puts "  Skip: Passkey already exists for user #{credential.user.email}"
          next
        end

        # Passkey レコード作成
        passkey = Passkey.new(
          user: credential.user,
          identifier: normalized_identifier,
          public_key: credential.public_key,
          sign_count: credential.sign_count || 0,
          last_used_at: credential.updated_at,
          label: "移行済みデバイス (#{credential.created_at.strftime('%Y-%m-%d')})"
        )

        if passkey.save
          migrated_count += 1
          puts "  ✓ Migrated credential for user: #{credential.user.email}"
        else
          error_count += 1
          puts "  ✗ Failed to migrate credential for user #{credential.user.email}: #{passkey.errors.full_messages.join(', ')}"
        end

      rescue => e
        error_count += 1
        puts "  ✗ Error migrating credential ID #{credential.id}: #{e.message}"
      end
    end

    puts "\nMigration completed:"
    puts "  Successfully migrated: #{migrated_count} credentials"
    puts "  Errors encountered: #{error_count} credentials"
    puts "  Total WebAuthn credentials: #{WebauthnCredential.count}"
    puts "  Total Passkeys after migration: #{Passkey.count}"
  end

  desc "Verify migration integrity"
  task verify: :environment do
    puts "Verifying migration integrity..."

    webauthn_count = WebauthnCredential.count
    passkey_count = Passkey.count

    puts "WebAuthn credentials: #{webauthn_count}"
    puts "Passkeys: #{passkey_count}"

    # ユーザー毎の比較
    User.joins(:webauthn_credentials).distinct.find_each do |user|
      webauthn_creds = user.webauthn_credentials.count
      passkeys = user.passkeys.count

      if webauthn_creds != passkeys
        puts "  ⚠️ User #{user.email}: WebAuthn(#{webauthn_creds}) != Passkeys(#{passkeys})"
      else
        puts "  ✓ User #{user.email}: Matched (#{passkeys})"
      end
    end
  end

  desc "Cleanup old WebAuthn data (use with caution)"
  task cleanup: :environment do
    print "Are you sure you want to delete all WebAuthn credentials? (yes/NO): "
    confirmation = STDIN.gets.chomp

    if confirmation.downcase == "yes"
      deleted_count = WebauthnCredential.count
      WebauthnCredential.destroy_all
      puts "Deleted #{deleted_count} WebAuthn credentials"
    else
      puts "Cleanup cancelled"
    end
  end
end
