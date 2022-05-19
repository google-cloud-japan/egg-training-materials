CREATE DATABASE IF NOT EXISTS game;
USE game;
CREATE TABLE IF NOT EXISTS game.game_event (
game_id VARCHAR(54) NOT NULL PRIMARY KEY,
game_server VARCHAR(36),
game_type VARCHAR(19),
game_map VARCHAR(10),
event_datetime DATETIME,
player VARCHAR(17),
killed VARCHAR(17),
weapon VARCHAR(11),
x_cord INT,
y_cord INT
);

INSERT INTO game.game_event (game_id, game_server, game_type, game_map, event_datetime, player, killed, weapon, x_cord, y_cord) VALUES
('wornoutZebra7-9846610-3946251292168118268992823970','Jeff & Julius Resurrection Server','Keyhunt','boil','2019-03-03 02:34:34','goofyWhiting7','boastfulPonie4','Hagar',29,54),
('enviousCaviar1-2811973-5883011126555021604525054585','[WTWRP] Votable','Keyhunt','atelier','2019-03-01 03:19:30','needfulTermite0','abjectTermite7','Hagar',83,82),
('spiritedTeal8-2651047-991418688923765348873793999','exe.pub | Relaxed Running | CTS/XDF','Keyhunt','atelier','2019-03-03 08:10:31','murkyDinosaur5','puzzledPepper6','Hagar',6,33),
('innocentIguana4-3029130-6481117659747845226335614333','[WTWRP] Deathmatch','Complete This Stage','atelier','2019-02-09 03:36:51','resolvedDove6','worriedEagle0','Hagar',86,19),
('mellowRelish7-3773375-501322700940889343206866273','[WTWRP] Deathmatch','Keyhunt','atelier','2019-04-22 07:25:33','importedMuesli6','awedPlover0','Hagar',1,55),
('exactingSardines4-4698944-4718335854529873060120395926','Corcs do Harleys Xonotic Server','Keyhunt','boil','2019-03-18 03:32:35','dopeyThrushe0','pitifulBobolink2','Hagar',43,50),
('ashamedIcecream5-8556566-2736335361664276838110754239','[PAC] Pickup','Keyhunt','atelier','2019-03-18 03:37:06','lyingLard2','amusedMallard3','Hagar',1,60),
('vengefulPup3-8239445-4214337680396181440470745962','exe.pub | Relaxed Running | CTS/XDF','Deathmatch','atelier','2019-04-05 03:03:40','sugaryPie3','artisticOrange2','Hagar',77,18),
('enviousRuffs6-7892691-1550528495727726385159862586','Corcs do Harleys Xonotic Server','Keyhunt','atelier','2019-02-10 03:52:03','lovesickIcecream3','murkyTermite1','Hagar',29,36),
('sheepishSalami1-2471622-138762091842251200148673610','[PAC] Pickup','Keyhunt','atelier','2019-03-01 03:55:55','stressedOatmeal2','bubblyLlama5','Hagar',34,31),
('holisticPiglet1-625829-9979821398420284830925744039','Jeffs Vehicle Warfare','Capture The Flag','atelier','2019-03-16 18:23:40','zestyCardinal1','sheepishWeaver8','Hagar',36,75),
('goofyIcecream9-9803832-3306029863902563096108131556','exe.pub | Relaxed Running | CTS/XDF','Team Death Match','atelier','2019-03-06 06:31:32','zestyHeron1','wakefulToucan5','Hagar',0,5),
('worldlyLocust2-155667-3205310712476281232789561639','Jeffs Vehicle Warfare','Keyhunt','atelier','2019-01-25 06:37:20','similarWidgeon2','annoyedGarlic0','Hagar',48,37),
('somberPup8-4419784-861776068945108190817030775','[WTWRP] Deathmatch','Keyhunt','stormkeep','2019-01-18 03:44:22','relievedAntelope6','annoyedFlamingo5','Hagar',34,14),
('jealousPolenta5-1945566-3868216227011810904410677459','(SMB) Kansas Public [git]','Keyhunt','atelier','2019-03-27 07:59:43','grumpySalt3','peacefulAbalone6','Hagar',0,59),
('aloofOwl1-1142026-8438109611603644321370291847','[PAC] Pickup','Deathmatch','atelier','2019-01-07 03:39:25','needyThrushe8','cheerfulJerky1','Hagar',32,36),
('betrayedPorpoise0-2738890-9551382928703013547238113747','Odjel za Informatikus Xonotic Server','Keyhunt','atelier','2019-03-02 18:28:46','insecureChough4','aloofBass2','Hagar',74,16),
('similarCaviar4-9289104-1736514877328485665860161423','Odjel za Informatikus Xonotic Server','Keyhunt','darkzone','2019-03-02 03:33:03','ecstaticBaboon6','wornoutOryx9','Hagar',65,14),
('zestyKitten2-5647495-5606568091525682796365088353','Jeff & Julius Resurrection Server','Keyhunt','atelier','2019-03-08 03:36:21','dearSeagull4','mereTacos8','Hagar',12,60),
('cruelGnu6-6094385-784463176482035485334252491','exe.pub | Relaxed Running | CTS/XDF','Keyhunt','atelier','2019-01-06 03:20:06','debonairRhino6','murkySausage5','Hagar',17,21);
