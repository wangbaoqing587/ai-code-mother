use ai_code_mother;

update user set gender = case when gender = 'female' then 0 else 1 end;

alter table user
    modify column gender tinyint default 1 not null comment '性别：1男 0女';
