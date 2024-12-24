/*
A predicate is a condition over a subject and a resource that must hold for a
rule to fire. Predicates are written as JMESPath queries over a JSON object
with two fields `subject` and `resource` that contain subject and resource
properties respectively:

 {
    subject: {..},
    resource: {..}
 }

JMESPath is a query language, similar to JSONPath, with thie added
benefit that it supports boolean conditions over JSON documents.
*/
create type predicate_t as string;

/* We model properties of an object as a JSON map. */
create type properties_t as variant;


/*
We use strings as unique ids. This is not an efficient choice, but it
helps for illustrative purposes, as we can refer to various entities by name.
*/
create type id_t as string;

/*
Validate JMESPath expression against subject and resource properties. Returns `true`
if the expression evaluates to `true`, `false` if it evaluates to any other value
and `NULL` if `condition` is not a valid JMESPAth expression.
*/
create function check_condition(
    condition predicate_t,
    subject_properties properties_t,
    resource_properties properties_t
) returns boolean;

/*
All entities in the system, including both users and resources.
*/
create table all_objects (
    id id_t not null primary key,
    properties properties_t
);

/*
Edges in the authorization graph that represent basic facts about the system specified by the user.

Other facts are derived from basic facts using rules.
An edge specifies a subject, a resource, and a relation betweent them, e.g.,
(folder1, folder2, is_parent) or (user1, group1, is_member).
*/
create table edges (
    subject_id id_t not null,
    resource_id id_t not null,
    relation_id id_t not null
);

/*
A subset of currently active objects.

This table is a subset of object ids, including only those objects for which authorization rules need to be evaluated.
The definition of an "active object" varies depending on the application and may include, for example, folders or wiki pages
currently accessed or open by at least one user.
*/
create table active_objects(
    object_id id_t not null
);

/*
Relevant objects are all active objects plus all objects from which
an active objects can be reached by following graph edges.
*/
declare recursive view relevant_objects(
    object_id id_t not null
);

create view relevant_objects as
select * from active_objects
union all
select edges.subject_id
    from relevant_objects join edges on relevant_objects.object_id = edges.resource_id;

/*
Objects whose id's are in `relevant_objects`.
*/
create materialized view objects as
select all_objects.*
    from all_objects join relevant_objects on all_objects.id = relevant_objects.object_id;

/*
Rules with one pre-requisite.

Example rule: "The owner of an object can read the object if they are not banned and the object has not been deleted."

 Prerequisite relation: is_owner
 Condition: !subject.banned && !resource.deleted
 Derived relation: can_read
*/
create table unary_rules (
    prerequisite_relation_id id_t,
    condition predicate_t,
    derived_relation_id id_t
) with ('materialized' = 'true');


/*
Rules with two pre-requisites.

Example rule: "If a user is a member of a group and the group has write access to an object, then the user has read access to the object."

 Prerequisite relation 1: is_member
 Prerequisite relation 2: can_read
 Condition: !subject.banned && !resource.deleted
 Derived relation: can_read
*/
create table binary_rules (
    prerequisite1_relation_id id_t,
    prerequisite2_relation_id id_t,
    condition predicate_t,
    derived_relation_id id_t
) with ('materialized' = 'true');

/*
All (subject, resource, relation) tuples that can be derived by transitively applying the rules to the authorization graph.
*/
declare recursive view relationships (
    subject_id id_t,
    resource_id id_t,
    relation_id id_t
);

/* Authorization tuples derived using unary rules. */
declare recursive view derived_unary_relationships (
    subject_id id_t,
    resource_id id_t,
    relation_id id_t
);

/* Authorization tuples derived using binary rules. */
declare recursive view derived_binary_relationships (
    subject_id id_t,
    resource_id id_t,
    relation_id id_t
);

create materialized view derived_unary_relationships as
select
    relationships.subject_id,
    relationships.resource_id,
    unary_rules.derived_relation_id as relation_id
from
    relationships
    join unary_rules on relationships.relation_id = unary_rules.prerequisite_relation_id
    join objects subject on subject.id = relationships.subject_id
    join objects resource on resource.id = relationships.resource_id
where
    check_condition(unary_rules.condition, subject.properties, resource.properties);

create materialized view derived_binary_relationships as
select
    r1.subject_id,
    r2.resource_id,
    binary_rules.derived_relation_id as relation_id
from
relationships r1
    join binary_rules on r1.relation_id = binary_rules.prerequisite1_relation_id
    join relationships r2 on r1.resource_id = r2.subject_id and binary_rules.prerequisite2_relation_id = r2.relation_id
    join objects subject on subject.id = r1.subject_id
    join objects resource on resource.id = r2.resource_id
where
    check_condition(binary_rules.condition, subject.properties, resource.properties);

create materialized view relationships as
select * from edges
UNION ALL
select * from derived_unary_relationships
UNION ALL
select * from derived_binary_relationships;
