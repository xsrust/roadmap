namespace :migrate do
  desc "TODO"
  task permissions: :environment do
    User.update_user_permissions
  end

  desc "perform entire data migration"
  task setup: :environment do
    Rake::Task['db:drop'].execute
    Rake::Task['db:create'].execute
    Rake::Task['db:schema:load'].execute
    Rake::Task['db:data:load'].execute
    Rake::Task['db:migrate'].execute
    Rake::Task['migrate:seed'].execute
    Rake::Task['migrate:permissions'].execute
  end

  desc "seed database with default values for new data structures"
  task seed: :environment do
    # seed roles to database
    roles = {
      'add_organisations' => {
        name: 'add_organisations'
      },
      'change_org_affiliation' => {
        name: 'change_org_affiliation'
      },
      'grant_permissions' => {
        name: 'grant_permissions'
      },
      'modify_templates' => {
        name: 'modify_templates'
      },
      'modify_guidance' => {
        name: 'modify_guidance'
      },
      'use_api' => {
        name: 'use_api'
      },
      'change_org_details' => {
        name: 'change_org_details'
      },
      'grant_api_to_orgs' => {
        name: 'grant_api_to_orgs'
      }
    }
    roles.each do |role, details|
      if Role.where(name: details[:name]).empty?
        role = Role.new
        role.name = details[:name]
        role.save!
      end
    end

    # seed token permission types to database
    token_permission_types = {
        'guidances' => {
            description: "allows a user access to the guidances api endpoint"
        },
        'plans' => {
            description: "allows a user access to the plans api endpoint"
        },
        'templates' => {
            description: "allows a user access to the templates api endpoint"
        },
        'statistics' => {
            description: "allows a user access to the statistics api endpoint"
        }
    }
    token_permission_types.each do |title,settings|
      if TokenPermissionType.where(token_type: title).empty?
        token_permission_type = TokenPermissionType.new
        token_permission_type.token_type = title
        token_permission_type.text_description = settings[:description]
        token_permission_type.save!
      end
    end

    # seed languages to database
    languages = {
        'English(UK)' => {
            abbreviation: 'en-UK',
            description: 'UK English language used as default',
            name: 'English(UK)',
            default_language: true
        },
        'FR' => {
            abbreviation: 'fr',
            description: '',
            name: 'fr',
            default_language: false
        },
        'DE' => {
            abbreviation: 'de',
            description: '',
            name: 'de',
            default_language: false
        }
    }

    languages.each do |l, details|
      if Language.where(name: details[:name]).empty?
        language = Language.new
        language.abbreviation = details[:abbreviation]
        language.description = details[:description]
        language.name = details[:name]
        language.default_language = details[:default_language]
        language.save!
      end
    end

    # seed regions to database
    regions = {
        'UK' => {
            abbreviation: 'uk',
            description: 'default region',
            name: 'UK',
        },
        'DE' => {
            abbreviation: 'de',
            description: '',
            name: 'DE',
        },
        'Horizon2020' => {
            abbreviation: 'horizon',
            description: 'European super region',
            name: 'Horizon2020',
        }
    }

    regions.each do |l, details|
      if Region.where(name: details[:name]).empty?
        region = Region.new
        region.abbreviation = details[:abbreviation]
        region.description = details[:description]
        region.name = details[:name]
        region.save!
      end
    end

  end
  
  desc "Remove orphaned records from the database"
  task data_integrity: :environment do
    # Look for orphaned records in the join tables:

    # Remove orphaned records from answers_options
    execute "DELETE FROM answers_options WHERE answer_id IS NULL OR option_id IS NULL;"
    execute "DELETE FROM answers_options WHERE answer_id NOT IN (SELECT id FROM answers);"
    execute "DELETE FROM answers_options WHERE option_id NOT IN (SELECT id FROM options);"

    # Remove orphaned records from dmptemplates_guidance_groups
    execute "DELETE FROM dmptemplates_guidance_groups WHERE dmptemplate_id IS NULL OR guidance_group_id IS NULL;"
    execute "DELETE FROM dmptemplates_guidance_groups WHERE dmptemplate_id NOT IN (SELECT id FROM dmptemplates);"
    execute "DELETE FROM dmptemplates_guidance_groups WHERE guidance_group_id NOT IN (SELECT id FROM guidance_groups);"
    
    # Remove orphaned records from guidance_in_group
    execute "DELETE FROM guidance_in_group WHERE guidance_id IS NULL OR guidance_group_id IS NULL;"
    execute "DELETE FROM guidance_in_group WHERE guidance_id NOT IN (SELECT id FROM guidances);"
    execute "DELETE FROM guidance_in_group WHERE guidance_group_id NOT IN (SELECT id FROM guidance_groups);"
    
    # Remove orphaned records from plan_sections
    execute "DELETE FROM plan_sections WHERE plan_id IS NULL OR section_id IS NULL OR user_id IS NULL;"
    execute "DELETE FROM plan_sections WHERE plan_id NOT IN (SELECT id FROM plans);"
    execute "DELETE FROM plan_sections WHERE section_id NOT IN (SELECT id FROM sections);"
    execute "DELETE FROM plan_sections WHERE user_id NOT IN (SELECT id FROM users);"
    
    # TODO: xsrust: does this one seem appropriate? I can't see a scenario 
    #               where it would be valid for user_id or project_id to 
    #               be null
    # Remove orphaned records from project_groups
    execute "DELETE FROM project_groups WHERE user_id IS NULL OR project_id IS NULL;"
    execute "DELETE FROM project_groups WHERE user_id NOT IN (SELECT id FROM users);"
    execute "DELETE FROM project_groups WHERE project_id NOT IN (SELECT id FROM projects);"
    
    # Remove orphaned records from project_guidance
    execute "DELETE FROM project_guidance WHERE project_id IS NULL OR guidance_group_id IS NULL;"
    execute "DELETE FROM project_guidance WHERE project_id NOT IN (SELECT id FROM projects);"
    execute "DELETE FROM project_guidance WHERE guidance_group_id NOT IN (SELECT id FROM guidance_groups);"

    # Remove orphaned records from questions_themes
    execute "DELETE FROM questions_themes WHERE question_id IS NULL OR theme_id IS NULL;"
    execute "DELETE FROM questions_themes WHERE question_id NOT IN (SELECT id FROM questions);"
    execute "DELETE FROM questions_themes WHERE theme_id NOT IN (SELECT id FROM themes);"
    
    # Remove orphaned records from themes_in_guidance
    execute "DELETE FROM themes_in_guidance WHERE theme_id IS NULL OR guidance_id IS NULL;"
    execute "DELETE FROM themes_in_guidance WHERE theme_id NOT IN (SELECT id FROM themes);"
    execute "DELETE FROM themes_in_guidance WHERE guidance_id NOT IN (SELECT id FROM guidances);"
    
    # Remove orphaned records from user_org_roles
    execute "DELETE FROM user_org_roles WHERE user_id IS NULL;"
    execute "DELETE FROM user_org_roles WHERE user_id NOT IN (SELECT id FROM users);"
    execute "DELETE FROM user_org_roles WHERE organisation_id NOT IN (SELECT id FROM organisations);"
    
    # Remove orphaned records from users_roles 
    execute "DELETE FROM users_roles WHERE user_id IS NULL OR role_id IS NULL;"
    execute "DELETE FROM users_roles WHERE user_id NOT IN (SELECT id FROM users);"
    execute "DELETE FROM users_roles WHERE role_id NOT IN (SELECT id FROM roles);"
    
    Rake::Task['migrate:remove_invalid_emails'].execute
  end
  
  desc "Remove invalid user email addresses"
  task remove_invalid_emails: :setup_logger do
    adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]

    # Unfortunately Postgres and Mysql handle regexes differently
    if adapter.include?("mysql")
      bad_emails = User.where("email NOT REGEXP '@([-a-z0-9]+\.)+[a-z]{2,}'")
    else
      bad_emails = User.where("email !~ '@([-a-z0-9]+\.)+[a-z]{2,}'")
    end
    
    unless bad_emails.empty?
      bad_emails.each do |usr|
        tmp = "#{SecureRandom.uuid(8)}@replacement-email.org"
        Rails.logger.warn "Replacing invalid email address for name: #{usr.name}, id: #{usr.id}, email: #{usr.email} with #{tmp}"
        usr.email = tmp
        usr.save!
      end
      puts "#{bad_emails.count} #{bad_emails.count > 1 ? 'users' : 'user'} with bad invalid addresses were detected. These emails have been replaced. See log/migration.log for more details."
    end
  end
  
  desc "Setup the log/migration.log"
  task setup_logger: :environment do
    Rails.logger = Logger.new('log/migration.log')
    Rails.logger.level = Logger::INFO
  end
end
