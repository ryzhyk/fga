use std::collections::BTreeMap;
use feldera_sqllib::Variant;

pub fn check_condition(
    condition: Option<String>,
    subject_properties: Option<Variant>,
    resource_properties: Option<Variant>)
-> Result<Option<bool>, Box<dyn std::error::Error>> {
    Ok(do_check_condition(condition, subject_properties, resource_properties))
}

pub fn do_check_condition(
    condition: Option<String>,
    subject_properties: Option<Variant>,
    resource_properties: Option<Variant>)
-> Option<bool> {
    //println!("check_condition({condition:?},{subject_properties:?},{resource_properties:?})");
    let condition = condition?;
    let subject_properties = subject_properties?;
    let resource_properties = resource_properties?;

    let expr = jmespath::compile(&condition).map_err(|e| println!("invalid jmes expression: {e}")).ok()?;
    let all_properties = Variant::Map(BTreeMap::from(
        [(Variant::String("subject".to_string()), subject_properties),
         (Variant::String("resource".to_string()), resource_properties)]));

    //println!("condition: {condition:?}, properties: {}", serde_json::to_string(&all_properties).unwrap());

    let result = expr.search(all_properties).map_err(|e| println!("error evaluating jmes expression: {e}")).ok()?;
    //println!("result: {result:?}");
    Some(result.as_ref() == &jmespath::Variable::Bool(true))
}
