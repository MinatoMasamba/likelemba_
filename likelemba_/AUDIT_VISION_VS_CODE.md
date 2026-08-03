# Likelemba Sécurisé — Vision documentée vs. code livré

*Revue basée sur une lecture ligne à ligne des apps `users`, `tontines`, `transactions`, `sync`, `analytics` et `core`, et sur l'extraction texte des six documents `.docx` présents à la racine du dépôt. Rédigé le 3 août 2026.*

> **Mise à jour du 3 août 2026** — Les 7 bugs listés en section 5 sont corrigés (le 7ᵉ, plus grave que les six premiers, a été découvert en écrivant les tests de régression : voir la note en tête de section). La configuration (§6, durcissement) et la synchronisation offline (§6, résolution des FK + câblage Celery) ont été implémentées. `apps/tontines/tests.py` et `apps/analytics/tests.py` couvrent désormais le moteur financier. Le texte ci-dessous est conservé tel quel pour l'historique de la revue ; le statut à jour de chaque point est noté entre crochets.

**Dépôt** : `likelemba_/likelemba_`
**Code** : Django 5.2 + DRF — apps `users` / `tontines` / `transactions` / `sync` / `analytics`
**Docs** : 6 fichiers `.docx` à la racine

---

## Sommaire

1. [Résumé exécutif](#1-résumé-exécutif)
2. [La vision documentée](#2-la-vision-documentée)
3. [Ce que le code livre réellement](#3-ce-que-le-code-livre-réellement)
4. [Vision ↔ code, poste par poste](#4-vision--code-poste-par-poste)
5. [Bugs relevés dans le code actuel](#5-bugs-relevés-dans-le-code-actuel)
6. [Ce qui manque pour la vision complète](#6-ce-qui-manque-pour-la-vision-complète)
7. [Ce que l'interface mobile attendra de cette API](#7-ce-que-linterface-mobile-attendra-de-cette-api)
8. [Priorités](#8-priorités)

---

## 1. Résumé exécutif

Les six fichiers Word décrivent un produit fini : une application mobile **Flutter**, base de données locale **Isar**, interface **« Liquid Glass »** à 120 FPS, moteur de risque par **IA embarquée**, le tout gouverné par un modèle mathématique par équations différentielles ordinaires (EDO) pour sécuriser le fonds de réserve. C'est un travail de conception sérieux et cohérent en interne.

Le dépôt, lui, ne contient **aucune ligne de Flutter, Dart ou Isar**. Il contient un **backend Django REST Framework** qui implémente une bonne partie de la logique financière décrite dans les docs — le calcul de remboursement dégressif et le solveur EDO sont même remarquablement fidèles aux formules du document mathématique. Mais l'interface qui devait consommer cette API n'existe nulle part dans ce dépôt, et plusieurs fonctionnalités back-end critiques (temps réel, notifications push, IA de risque) ne sont que des champs de base de données sans logique derrière.

Au passage, la revue du code a mis au jour **six bugs concrets** dans les couches les plus utilisées (création de groupe, remplacement de membre, acceptation d'adhésion) — détaillés en section 5 — plus un septième, plus grave, découvert en écrivant les tests de régression : le calcul de remboursement lui-même plantait à chaque appel réel. **Les 7 bugs sont corrigés**, la synchronisation offline et la configuration de production ont été durcies, et une première suite de tests couvre désormais le moteur financier (voir la note de mise à jour ci-dessus).

| | |
|---|---|
| **~70 %** | de la logique financière EDO est implémentée côté serveur et correspond aux formules des docs |
| **0** | fichier Flutter/Dart trouvé dans le dépôt — l'app mobile décrite dans les docs n'a pas de code |
| **7 → 0** | bugs confirmés dans le code — tous corrigés et couverts par des tests de non-régression |

---

## 2. La vision documentée

Les six `.docx` se recoupent largement. Trois d'entre eux (*Modélisation Mathématique*, *Modélisation EDO*, *Document sans titre*) posent le même socle scientifique avec des variantes de rédaction — l'un est un « travail scientifique » signé façon mémoire universitaire (UNIKIN), un autre vulgarise le même contenu pour des membres non-techniques. Les deux autres (*Architecture Systémique*, *Solutions Web*) détaillent l'implémentation Flutter attendue. Ensemble, ils dessinent quatre couches de vision.

### 2.1 — Le moteur mathématique du fonds de réserve

L'idée centrale : chaque cotisation quotidienne `s` comprend un prélèvement de sécurité `a` qui alimente un fonds de réserve `F(t)`, traité comme un réservoir d'eau — l'analogie revient dans trois des six documents. Un membre qui part avant d'avoir reçu sa cagnotte récupère son argent moins une pénalité qui décroît linéairement avec le temps passé dans le groupe.

**Évolution du fonds (régime nominal) :**
```
dF/dt = n·a − λ·R(t)
```

**Pénalité dégressive au jour τ :**
```
α(τ) = α₀·(1 − τ/T)
```

**Remboursement dû à un départ au jour τ :**
```
R(τ) = s·τ·[1 − α(τ)]
```

| Variable | Rôle |
|---|---|
| `n` | Nombre de cotisants actifs |
| `s` | Cotisation journalière par membre |
| `a` | Part de `s` prélevée pour le fonds de réserve |
| `T` | Durée totale du cycle, en jours |
| `α₀` | Taux de pénalité initial (documents : 15–25 %) |
| `F(t)` | Montant du fonds de réserve à l'instant t |

Les docs couvrent aussi des cas limites : départs multiples successifs, absence de remplaçant (le flux tombe à `(n−1)·a`), et le « danger du départ tardif » où un remboursement quasi-total en fin de cycle peut rendre `F(T)` négatif — un des documents y consacre une démonstration dédiée avec proposition de plafonnement.

### 2.2 — L'application mobile Flutter

L'*Architecture Systémique* prescrit une Clean Architecture en quatre couches (domaine, données, application, présentation), une organisation « feature-first » (`features/auth`, `features/tontine`, `features/transactions`, `features/admin`, `features/sync`), et **Isar** comme base locale réactive avec transactions ACID (`isar.writeTxn`) pour garantir qu'une cotisation validée met à jour solde membre et fonds de réserve de façon atomique.

La stratégie offline-first repose sur un **pattern Transactional Outbox** : chaque action est écrite localement avec `isSync = false`, puis un moteur de synchronisation la rejoue au serveur en FIFO dès qu'une connexion est détectée, avec retry en backoff exponentiel.

### 2.3 — L'interface « Liquid Glass »

Un glassmorphism poussé, rendu via le moteur **Impeller** à 120 FPS avec des shaders `.frag` personnalisés, deux niveaux de qualité (standard pour les listes, premium pour l'AppBar), et des specs précises : opacité 10–40 %, flou 12–20px, bordure 1px blanche à 10 % d'alpha, transitions 200–400ms. Un mode « contraste élevé » et des retours haptiques distincts par type d'événement couvrent l'accessibilité.

### 2.4 — IA embarquée et pilotage admin

Un modèle de risque tourne *on-device* via LiteRT (ex-TensorFlow Lite), quantifié en INT8, pour prédire les retards de paiement sans faire sortir de données de l'appareil. L'admin dispose d'un tableau de bord — cartes de membres dynamiques, simulateur de remboursement, moniteur de fonds en temps réel via `fl_chart`/`cristalyse` — qui segmente automatiquement les participants en quatre vues : contributeurs, sortants, engagements futurs, nouveaux ajouts.

---

## 3. Ce que le code livre réellement

Le dépôt est un projet Django 5.2 / DRF classique, en SQLite, avec cinq apps métier plus un socle `core`. Pas de `pubspec.yaml`, pas de fichier `.dart`, pas de dossier front — l'intégralité du dépôt est le service API.

| App | Contenu | Endpoints principaux |
|---|---|---|
| `apps.users` | User (téléphone comme identifiant), UserProfile (risk_score, langue, stats), UserDevice | `auth/register`, `auth/token`, `profile`, `biometric/*`, `devices` |
| `apps.tontines` | LikelembaGroup, Cycle, Membership, QueuePosition, JoinRequest | `groups/`, `cycles/`, `memberships/`, `queue/`, `join-requests/` |
| `apps.transactions` | Contribution, Refund, Payout (héritent d'un modèle Transaction abstrait) | `contributions/`, `refunds/`, `payouts/` |
| `apps.sync` | SyncBatch, SyncOperation — implémentation serveur de l'Outbox | `sync/upload/`, `sync/status/<batch_id>/` |
| `apps.analytics` | Aucun modèle propre — expose le solveur EDO | `analytics/projection/`, `analytics/simulate/` |
| `core` | BaseModel (UUID + timestamps), permissions (IsGroupMember, IsGroupAdmin), gestionnaire d'exceptions métier | — |

### Le moteur EDO — la partie la plus aboutie

`apps/tontines/services.py` et `apps/analytics/services.py` traduisent les formules des documents presque littéralement.

| Formule du document | Implémentation | |
|---|---|---|
| `R(τ) = s·τ·[1 − α₀·(1 − τ/T)]` | `LikelembaCalculator.calculate_refund()` | ✅ Fidèle |
| `dF/dt = n·a − λ·R(t)` | `ProjectionService.solve_edo()` | ✅ Fidèle |
| Simulation de départs multiples | `ProjectionService.simulate_exits()` | ✅ Présent |
| Temps de reconstitution du fonds | `calculate_recovery_time()` | ✅ Présent |
| Plafonnement / interdiction de sortie tardive | Aucune contrainte de ce type dans le code | ❌ Absent |

Le solveur numérique utilise `numpy`/`scipy` comme prévu dans `requirements.txt`, avec une discrétisation jour par jour plutôt qu'une intégration continue — un choix pragmatique cohérent avec l'usage (projections à 30–60 jours), même si ce n'est pas littéralement une résolution d'EDO.

---

## 4. Vision ↔ code, poste par poste

| Élément documenté | État | Constat |
|---|---|---|
| Calcul de pénalité dégressive | ✅ Implémenté | Formule exacte, testable, isolée dans `LikelembaCalculator` |
| Projection EDO du fonds de réserve | ✅ Implémenté | Endpoint `analytics/projection/` fonctionnel |
| Remplacement immédiat de membre | ✅ Implémenté | Bug #3 (positions spécifiques) corrigé et testé |
| File d'attente / tour de cagnotte | ✅ Implémenté | `QueuePosition` + avancement automatique dans `process_payout` |
| Demandes d'adhésion par code d'invitation | ✅ Implémenté | Bug #5 (acceptation) corrigé et testé |
| Transactional Outbox / sync offline | ✅ Implémenté | Résolution des FK ajoutée, gros lots délégués à Celery — voir §6 |
| Application mobile Flutter | ❌ Absent | Aucun fichier Dart dans le dépôt |
| Base de données locale Isar | ❌ Absent | N/A côté serveur ; c'était toujours prévu côté mobile |
| Interface « Liquid Glass » / Impeller | ❌ Absent | Aucune UI dans ce dépôt, backend seul |
| IA embarquée de prédiction de risque | ❌ Absent | `risk_score` existe sur `UserProfile` mais rien ne le calcule, côté serveur ou mobile |
| Notifications temps réel (watchers / WebSocket) | ❌ Absent | Pas de `channels`, pas de WebSocket ; `UserDevice.push_token` existe mais rien n'envoie de push |
| Vérification SMS du téléphone | ❌ Absent | `PhoneVerificationConfirmView` accepte le code en dur `"123456"` — un simulateur, pas un vrai envoi |
| Dashboard admin (cartes, simulateur, moniteur) | ✅ Implémenté (en Django templates) | `apps/dashboard/` : pages membre + admin servies en HTML (session Django, pas Flutter/Liquid Glass) — évolution du fonds, évolution des membres, 4 catégories, file d'attente, adhésions, cotisations en attente. Voir §9. |

---

## 5. Bugs relevés dans le code actuel

**[Statut : les 7 bugs ci-dessous sont corrigés.]** Les six premiers ont été vérifiés en lisant le code ligne à ligne, pas déduits par inspection superficielle. Un septième, plus grave que tous les autres, a été découvert après coup en écrivant les tests de régression de `LikelembaCalculator.calculate_refund` (§10 de l'audit initial) : voir le point 7. Les trois-quatre premiers cassaient des parcours utilisés à chaque cycle de vie d'un groupe.

### 0 · Le calcul de remboursement plantait à chaque appel réel — 🔴 Critique (le plus grave)
**`apps/tontines/services.py` — `LikelembaCalculator.calculate_refund`**

Non détecté à la première lecture du code : `alpha = alpha_0 * (1 - days_participated / total_days)` produit un `float` (`alpha_0` est un `float`, comme `LikelembaGroup.penalty_rate_initial`). La ligne suivante, `refund = total_contributed * (1 - alpha)`, multiplie alors un `Decimal` (`total_contributed`) par un `float` — ce que Python interdit et lève systématiquement `TypeError: unsupported operand type(s) for *: 'decimal.Decimal' and 'float'`.

> **Impact réel, plus large que les six bugs ci-dessous** : c'était la formule centrale du projet — celle que les six documents `.docx` présentent comme l'innovation du système (« la pénalité dégressive »). Chaque départ de membre avant réception de cagnotte (`MembershipService.process_member_exit`) et chaque projection EDO avec un taux de départ non nul (`ProjectionService.solve_edo` avec `lambda_rate > 0`) plantait. **Correction** : tout le calcul est fait en `Decimal` (`alpha_0` converti via `Decimal(str(alpha_0))` plutôt que mélangé tel quel), ce qui élimine aussi l'imprécision binaire des flottants sur un calcul financier. Couvert par `CalculateRefundTests.test_accepts_float_alpha_0_like_the_model_field` et par le test de non-régression équivalent dans `apps/analytics/tests.py`.

### 1 · Créer un groupe plantait systématiquement — 🔴 Critique
**`apps/tontines/views.py:4, 47`**

Le fichier importe `from datetime import timezone` puis appelle `timezone.now()` dans `perform_create`. Le `timezone` du module `datetime` standard n'a pas de méthode `.now()` — c'est `django.utils.timezone` qu'il fallait importer.

> **Impact** : chaque `POST /groups/` levait une `AttributeError` avant même de créer le membership du créateur. **Correction** : import de `django.utils.timezone`. Au passage, le rôle attribué au créateur (`role=self.request.user.account_type`) a aussi été corrigé — il pouvait valoir `'participant'`, une valeur hors de `Membership.ROLE_CHOICES` (`member`/`admin`), ce qui aurait empêché le créateur d'administrer son propre groupe. Il vaut désormais toujours `'admin'`. Couvert par `GroupCreationRegressionTests`.

### 2 · Deux méthodes `join_by_code` portaient le même nom — 🟠 Moyen
**`apps/tontines/views.py:136 et 174`**

La classe définissait deux fois `join_by_code` avec le même `url_path`. En Python, la seconde définition écrase silencieusement la première dans le corps de classe — les 37 lignes de la première version (136–172) ne s'exécutaient jamais.

> **Impact** : pas de crash, mais du code mort qui trompait la lecture et doublait la maintenance pour rien. **Correction** : la première définition (POST seul) a été supprimée ; seule la version GET/POST unifiée subsiste.

### 3 · Remplacer un membre à une position précise plantait — 🔴 Critique
**`apps/tontines/services.py:9, 230`**

Le fichier importait `from apps.users import models` puis appelait `models.F('position')`. `apps.users.models` est le module des modèles utilisateur, pas `django.db.models` — il n'expose pas `F`. Le même faux ami existait dans `JoinRequestViewSet.get_queryset()` (`models.Q(...)`), non listé initialement car il n'avait pas encore été exercé par un test.

> **Impact** : `MembershipService.replace_member(..., position_to_take=X)` levait une `AttributeError` dès qu'un admin remplaçait un membre à une position spécifique plutôt qu'en fin de file — exactement le cas d'usage central décrit dans les docs (« remplacement immédiat »). **Correction** : `from django.db.models import F` (et `Q` pour le second cas). Couvert par `ReplaceMemberAtPositionRegressionTests`.

### 4 · Les URLs de validation d'adhésion ne pouvaient jamais matcher — 🔴 Critique
**`apps/tontines/urls.py:22`**

La route était déclarée `groups/<int:group_id>/members/<int:user_id>/validation/`. Mais `core.models.BaseModel` — dont héritent `LikelembaGroup` et `User` — utilise un `UUIDField` comme clé primaire, pas un entier auto-incrémenté.

> **Impact** : `MembershipValidationView` était inatteignable en pratique — tout appel avec un vrai UUID renvoyait 404 avant même d'entrer dans la vue. **Correction** : route changée en `<uuid:group_id>/<uuid:user_id>`.

### 5 · Accepter une demande d'adhésion plantait — 🔴 Critique
**`apps/tontines/views.py:321` · `apps/tontines/admin.py:264`**

Les deux endroits lisaient `join_request.user.profile.preferred_role`. Le modèle `UserProfile` (`apps/users/models.py`) n'a pas de champ `preferred_role` — ses champs sont `risk_score`, `language`, `notification_enabled`, `push_token`, `total_contributions`, `total_received`, `photo_user`, `successful_cycles`, `default_count`.

> **Impact** : `JoinRequestViewSet.accept()` levait une `AttributeError` à chaque tentative — un utilisateur ne pouvait jamais rejoindre un groupe via demande d'adhésion. **Correction** : le rôle est désormais toujours `'member'` à l'acceptation, plutôt que lu sur un champ inexistant — ce qui ferme au passage un risque d'élévation de privilège (rien n'empêchait un champ `preferred_role` auto-déclaré de valoir `'admin'`). Couvert par `JoinRequestAcceptRegressionTests`.

### 6 · La liste des demandes en attente d'un groupe était du code mort — 🟠 Moyen
**`apps/tontines/views.py:420`**

`pending_for_group` était décoré avec `@action(...)` mais défini au niveau du module, en dehors de toute classe `ViewSet` — l'indentation le plaçait juste après la fin de `MembershipValidationView`. `@action` n'a d'effet que sur les méthodes d'un `ViewSet` enregistré via un routeur.

> **Correction** : déplacé dans `JoinRequestViewSet` comme action `GET /join-requests/pending-for-group/?group_id=...`, à sa place logique aux côtés de `accept`/`reject`/`cancel`.

> **Impact** : aucune route n'expose cette fonctionnalité. Un admin n'a aucun moyen documenté de lister les demandes en attente pour un groupe.

---

## 6. Ce qui manque pour la vision complète

### L'application elle-même
C'est le manque structurant : deux des six documents décrivent en détail une app Flutter (architecture, base Isar, rendu Impeller, shaders) et ce dépôt ne contenait, jusqu'à cette passe, que le serveur qu'elle est censée appeler. Un tableau de bord en Django templates a depuis été ajouté (§9) pour donner un accès opérationnel en attendant — ce n'est pas un substitut à l'app mobile Liquid Glass décrite dans les docs, mais ce dépôt produit désormais au moins une interface utilisateur.

### Temps réel et notifications
Les docs promettent des mises à jour instantanées chez tous les participants dès qu'une cotisation est validée (« watchers Isar et WebSockets »). Le backend n'a ni `channels`, ni `daphne`, ni aucun mécanisme de push. `UserDevice.push_token` est collecté mais jamais utilisé — aucun service (FCM, APNs) n'est câblé pour s'en servir.

### Le pattern Outbox côté serveur — [corrigé]
`SyncEngine._create_instance` (`apps/sync/sync_engine.py`) faisait un `model_class.objects.create(**data)` avec le JSON brut envoyé par le client, sans résoudre les clés étrangères (un `cycle` ou une `membership` envoyés comme simples UUID textuels ne devenaient pas automatiquement des instances liées — Django exige une instance du modèle lié pour le nom de champ nu). Une méthode `_resolve_relations()` convertit désormais chaque champ `ForeignKey` présent dans le payload (`cycle` → `cycle_id`, etc.) avant `create()`/`update()`, ce qui accepte directement l'identifiant brut envoyé par le mobile.

### Le traitement asynchrone — [branché]
`tasks/sync_tasks.py` définissait une tâche Celery `process_sync_batch_async` jamais invoquée ; `SyncUploadView` traitait tout en synchrone dans la requête HTTP. `SyncUploadView.post()` délègue maintenant à cette tâche (`.delay()`) au-delà de `settings.SYNC_ASYNC_THRESHOLD` opérations (20 par défaut, configurable), en renvoyant 202 + statut `pending` — le client interroge alors `sync/status/<batch_id>/`. Au passage, `config/__init__.py` n'existait pas du tout : l'app Celery n'était donc jamais garantie d'être initialisée au démarrage de Django (`@shared_task` sans app active). Il a été créé, et `config/celery.py` enregistre désormais explicitement `tasks.sync_tasks` (ce module vit hors de `INSTALLED_APPS`, donc `autodiscover_tasks()` ne le voyait pas).

### IA de risque — toujours absent (hors scope de cette passe)
`UserProfile.risk_score` existe (défaut 50.0) mais aucun code — ni régression, ni forêt aléatoire, ni tâche planifiée — ne le met à jour. C'est un champ orphelin. Volontairement laissé de côté : c'est la pièce la plus exploratoire des docs (LiteRT on-device côté mobile), pas un correctif de code côté serveur.

### Durcissement production — [fait, sauf notes ci-dessous]
- `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS` viennent maintenant de l'environnement (`decouple.config`) dans `config/settings/base.py`, avec des défauts sûrs (`DEBUG=False`, hôtes restreints) plutôt que le `SECRET_KEY` en clair et `ALLOWED_HOSTS=['*']` d'origine.
- `config/settings/development.py` et `config/settings/production.py` étaient des fichiers **vides** — `config/celery.py` pointait même vers `config.settings.production` par défaut, qui aurait fait planter tout worker Celery au démarrage (`INSTALLED_APPS` indéfini). Les deux sont maintenant de vrais modules : `development.py` hérite de `base` (DEBUG forcé à True, emails en console) ; `production.py` impose Postgres, `ALLOWED_HOSTS` sans défaut permissif, cookies sécurisés, HSTS, et interdit le wildcard CORS.
- `psycopg2-binary` décommenté dans `requirements.txt` (nécessaire à `production.py`).
- Vérification SMS : le code en dur `"123456"` a été remplacé par un vrai code à 6 chiffres généré par requête, stocké 5 minutes dans le cache (Redis en prod — ajouté à `CACHES`), comparé en temps constant. Aucun fournisseur SMS n'est câblé (pas de compte Twilio disponible) : le code est journalisé côté serveur pour permettre le développement de bout en bout — à remplacer avant mise en production réelle.
- Tests : `apps/tontines/tests.py` et `apps/analytics/tests.py` couvrent maintenant `LikelembaCalculator`, `ProjectionService` et les régressions des bugs #1, #3, #5. `apps/__init__.py` manquait aussi (aucun `.py` ne le déclarait comme paquet), ce qui empêchait `manage.py test` sans argument de découvrir quoi que ce soit — corrigé.

### Décisions de schéma qui trahissent de l'hésitation
Les migrations `0002` → `0004` de `apps.users` déplacent `account_type` de `User` vers `UserProfile` puis le ramènent sur `User` en trois migrations consécutives, le 23 avril. Le résultat final est cohérent avec le modèle actuel, mais ça vaut la peine de vérifier qu'aucune donnée de `UserProfile.account_type` n'a été perdue en environnement partagé.

---

## 7. Ce que l'interface mobile attendra de cette API

En partant des specs Flutter des documents et de ce que l'API expose déjà, voici les attentes concrètes côté client — utile pour prioriser avant qu'une équipe mobile ne commence à intégrer.

| Attente du mobile | Ce que l'API offre aujourd'hui |
|---|---|
| Un flux temps réel pour la file d'attente et les soldes (docs : « chaque mouvement financier est répercuté instantanément ») | Rien — il faudra du polling côté client tant qu'il n'y a pas de WebSocket/SSE |
| Des identifiants stables et cohérents dans toutes les routes | Incohérence UUID vs `int` déjà repérée (bug #4) — à corriger avant toute intégration mobile |
| Un contrat de synchronisation offline robuste aux FK | [Corrigé] `SyncEngine` résout maintenant les champs `ForeignKey` (`cycle`, `membership`, …) envoyés comme identifiants bruts |
| Un score de risque à afficher sur les cartes membres admin | `risk_score` existe dans `UserProfileSerializer` mais reste figé à sa valeur par défaut |
| Un bouton « Demander l'argent » piloté par une logique serveur (tour actif + absence de dette) | La logique d'éligibilité existe côté serveur (`_check_payout_eligibility`) mais n'est pas exposée comme un champ calculé consultable avant action — le mobile devrait pouvoir lire cet état, pas seulement le déclencher |
| Recevoir une notification push à chaque validation de cotisation | `UserDevice.push_token` stocké, aucun envoi |
| Un lien d'invitation utilisable tel quel | `invite_link` pointe vers une action GET/POST qui existe (`join-by-code`) — cohérent, mais dupliqué (bug #2) et à nettoyer |

---

## 8. Priorités

### ✅ Fait (cette passe)
1. ~~Corriger l'import `timezone` dans `apps/tontines/views.py`~~ — corrigé, et le rôle du créateur de groupe fixé à `admin`.
2. ~~Corriger `models.F` dans `apps/tontines/services.py`~~ — corrigé (et `models.Q` dans `JoinRequestViewSet`, trouvé au passage).
3. ~~Remplacer `join_request.user.profile.preferred_role`~~ — corrigé : rôle toujours `'member'` à l'acceptation.
4. ~~Changer les routes de validation en `<uuid:group_id>/<uuid:user_id>`~~ — corrigé.
5. ~~Supprimer la définition morte de `join_by_code` et déplacer `pending_for_group`~~ — fait.
6. ~~Écrire des tests sur `LikelembaCalculator` et `ProjectionService`~~ — fait (`apps/tontines/tests.py`, `apps/analytics/tests.py`) ; a révélé un bug plus grave que les six premiers (`Decimal * float` dans `calculate_refund`, voir §5 point 0), maintenant corrigé et testé.
7. ~~Définir un format de payload de sync qui résout les FK~~ — fait (`SyncEngine._resolve_relations`).
8. ~~Brancher le traitement Celery de la sync~~ — fait, au-delà de `SYNC_ASYNC_THRESHOLD` opérations ; `config/__init__.py` (absent) créé pour que l'app Celery s'initialise réellement.
9. Durcissement production (`SECRET_KEY`/`DEBUG`/`ALLOWED_HOSTS` par env, `development.py`/`production.py` réels, cache Redis, vérification SMS par code temporaire) — fait, voir §6.

### 🟢 Reste à faire
10. **Clarifier où vit le code mobile Flutter** — dépôt séparé ou à initier ici — avant d'investir davantage côté API sans consommateur pour la valider. C'est le manque le plus structurant du projet (§6).
11. Brancher un vrai fournisseur SMS (Twilio ou autre) une fois l'app mobile en état de le consommer — le flux par code temporaire est prêt, seul l'envoi réel manque.
12. Temps réel (WebSocket/Channels) et notifications push (`UserDevice.push_token` est collecté mais inutilisé) — nécessitent une décision d'infrastructure (Channels ? SSE ? polling ?) avant implémentation.
13. Le score de risque IA reste la pièce la plus exploratoire des docs (LiteRT on-device) — raisonnablement la dernière chose à construire, une fois un client mobile capable de le consommer.
14. Étendre la couverture de tests aux vues (`transactions`, `sync`, `users`) — seule la couche `tontines`/`analytics`/`dashboard` a des tests pour l'instant.

---

## 9. Tableau de bord (`apps/dashboard/`)

En l'absence de client mobile Flutter dans ce dépôt (§2.2, §6), un tableau de bord servi en Django templates (session, pas JWT) donne un premier accès opérationnel aux données du backend — sans attendre l'app mobile. Accessible sur `/dashboard/`, connexion par numéro de téléphone.

- **Vue liste** (`/dashboard/`) : les groupes de l'utilisateur connecté, avec son rôle, le fonds de réserve et l'avancement du cycle.
- **Vue détail d'un groupe** (`/dashboard/groups/<id>/`), commune aux membres et aux admins :
  - **Évolution totale de l'argent** : total cotisé, total versé en cagnottes, total remboursé, fonds de réserve actuel — calculés à partir des `Contribution`/`Payout`/`Refund` réels, pas d'une projection.
  - **Trajectoire observée du fonds** : graphique SVG reconstitué à partir des mouvements réels (chaque cotisation validée ajoute `security_levy`, chaque remboursement soustrait son montant), comparée à la projection EDO théorique du même nombre de jours.
  - **Évolution des membres** : chronologie des arrivées/départs.
  - **Quatre catégories de membres** reprenant la segmentation décrite dans les docs (§2.4) : contributeurs à jour, engagements futurs, sortants, nouveaux ajouts.
  - **Section Administration** (visible seulement si `role='admin'`) : file d'attente avec retrait de membre, ajout d'un remplaçant à une position donnée, acceptation/refus des demandes d'adhésion, validation des cotisations en attente.
- Toute la logique métier est réutilisée telle quelle depuis `apps/tontines/services.py`, `apps/transactions/services.py` et `apps/analytics/services.py` — aucune règle n'est dupliquée entre l'API REST et le tableau de bord. `JoinRequestService` a été extrait de `JoinRequestViewSet` précisément pour ça : les deux interfaces appellent maintenant le même code.
- Vérifié par 6 tests (`apps/dashboard/tests.py`) et par un parcours de bout en bout via `curl` (connexion, affichage, acceptation d'une demande d'adhésion, mise à jour immédiate de la page) — pas de vérification dans un vrai navigateur, cet environnement n'en a pas.
