json.prettify!

json.plans @org_plans.each do |plan|
  json.id             plan.id
  json.grant_number   plan.grant_number
  json.title          plan.title

  json.template do
    json.title        plan.template.title
    json.id           plan.template.family_id
  end

  json.funder do
    json.name         (plan.template.org.funder? ? plan.template.org.name : '')
  end

  json.principal_investigator do
    json.name         plan.principal_investigator
  end

  json.data_contact do
    json.info         plan.data_contact
  end

  json.description    plan.description

  json.date_created   plan.created_at
  json.date_last_updated   plan.updated_at

  json.completion do
    json.total_questions     plan.questions.count
    json.answered_questions  plan.answers.count
  end

end
