# Pokemon Sauvages Visibles

Prototype pour Gen1Recomp 0.1.98 (Rouge, Bleu et Jaune).

## Fonctionnement

- lit la table de rencontres fusionnee de la carte active ;
- repere les vraies cases de hautes herbes avec le moteur ;
- choisit especes et niveaux avec les probabilites Gen 1 ;
- affiche jusqu'a quatre Pokemon sauvages dans les herbes ;
- lance le combat quand le joueur essaie d'entrer sur leur case ;
- supprime les rencontres aleatoires dans l'herbe ;
- ne modifie jamais la ROM ni la sauvegarde.

Les ROMs Rouge et Bleu ne contiennent que quelques sprites Pokemon pour la
vue de dessus. Le mod emploie donc `SPRITE_BIRD`, `SPRITE_FAIRY`,
`SPRITE_SEEL`, `SPRITE_SNORLAX` ou `SPRITE_MONSTER` selon l'espece. Jaune
possede quelques sprites supplementaires (Pikachu, Sandshrew, Oddish,
Bulbizarre, etc.) que le mod utilise automatiquement.

## Installation

Dans le launcher Gen1Recomp : **MODS -> Import mod .zip**, puis selectionner
`pokemon-sauvages-visibles-1.0.0.zip`.

Le paquet ne contient ni ROM, ni sauvegarde, ni ressource extraite.
