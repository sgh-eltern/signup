require 'roda'
require 'sequel/core'
require 'mail'

class App < Roda
  DB = Sequel.sqlite
  Sequel.extension :migration
  Sequel::Migrator.run(DB, File.expand_path('../db/migrations', __FILE__))
  DB.extension :date_arithmetic
  DB.freeze

  plugin :render, :escape=>true
  plugin :request_aref, :raise
  plugin :hooks
  plugin :flash
  plugin :route_csrf, :csrf_failure=>:clear_session

  secret = ENV.fetch('RODAUTH_SESSION_SECRET')
  plugin :sessions, :secret=>secret, :key=>'rodauth-demo.session'

  plugin :rodauth, :csrf => :route_csrf do
    db DB
    enable :login, :create_account, :email_auth, :logout
    require_login_confirmation? false
    email_from 'Elternbeirat SGH <verteiler@eltern-sgh.de>'

    create_account_autologin? false
    create_account_set_password? false
    create_account_button 'Konto erstellen'
    create_account_error_flash 'Konto konnte nicht erstellt werden (create_account_error_flash).'
    create_account_notice_flash 'Konto wurde erfolgreich angelegt (create_account_notice_flash).'
    create_account_route 'konto-anlegen'
    create_account_link "<p><a href=\"#{prefix}/konto-anlegen\">Neues Konto anlegen</a></p>"

    email_auth_email_subject 'Login-Link für den SGH Elternverteiler'
    email_auth_email_sent_notice_flash 'Wir haben einen Link zum Login an Ihre eMail-Adresse geschickt (email_auth_email_sent_notice_flash).'
    email_auth_email_recently_sent_error_flash 'Wir haben Ihnen bereits kürzlich einen Link zum Login geschickt. Bitte prüfen Sie Ihr Postfach und auch den SPAM-Ordner (email_auth_email_recently_sent_error_flash).'
    email_auth_error_flash 'Login ist fehlgeschlagen (email_auth_error_flash).'
    email_auth_request_error_flash 'TODO  (email_auth_request_error_flash).'
    no_matching_email_auth_key_message 'Login ist fehlgeschlagen. Der Link ist falsch oder veraltet (no_matching_email_auth_key_message).'
    email_auth_email_body do
      <<~MSG
        Hallo,

        jemand hat mit dieser eMail-Adresse ein Login beim SGH Elternverteiler
        beauftragt. Wenn Sie sich jetzt anmelden möchten, gehen Sie bitte zu
        folgender Adresse:

          #{email_auth_email_link}

        Falls Sie das nicht veranlasst haben, können Sie diese eMail ignorieren.

        Mit freundlichen Grüßen

        Ihr Elternbeirat des Schickhardt-Gymnasiums Herrenberg
      MSG
    end

    login_button 'Login'
    login_error_flash 'Login ist fehlgeschlagen (login_error_flash).'
    login_error_status 'TODO (login_error_status).'
    login_notice_flash 'TODO (login_notice_flash).'
    require_login_error_flash 'TODO (require_login_error_flash).'

    require_mail? false
    send_email_auth_email do
      mail = {
        from: email_from,
        to: email_to,
        subject: email_auth_email_subject,
        body: email_auth_email_body,
      }
      warn "TODO Enqueing mail: #{mail}"
    end
  end

  route do |r|
    r.rodauth

    r.root do
      view 'index'
    end

    r.get 'account' do
      rodauth.require_authentication
      view 'account'
    end
  end

  freeze
end

run App.freeze.app
