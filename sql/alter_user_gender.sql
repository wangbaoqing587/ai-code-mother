use ai_code_mother;

alter table user
    add column gender tinyint default 1 not null comment '性别：1男 0女' after userProfile;

update user set gender = 1 where gender is null;
