# Project Description

# This project investigated the extent to which language learners' reading speed of Spanish sentences with constructions varies as a function of their language proficiency and the association strength between a verb and a construction.

# Variables:
## DV: reading times (RTs) were measured in the following way: 
# 1) RTs for a whole sentence that includes a construction; 
# 2) RTs for the critical word (region 3) in a construction; 
# 3) RTs for the whole construction (region 2 + region 3 + region 4 + region 5)

## IVs: (i) proficiency (EIT_scores), (ii) verb-construction association strength (weak vs. strong), (iii) construction type (VaN, VenN, VdeN, VconN)

# STEPS:
# 1) calculating descriptives for raw RTs
# 2) data preparation (log-transformation)
# 3) data visualization: generating scatterplots and line graphs
# 4) mixed-effects linear modeling


# Loading packages
library(tidyverse) 
library(dplyr) 
library(car)
library(lme4)
library(ggplot2)
library (ggpubr)
library (lme4)
library(MuMIn)

# Reading .csv dataset with results of the self-paced reading experiment
spr <- read.csv("spr_data.csv")
head(spr)

# STEP 1: CALCULATING BASIC DESCRIPTIVE STATISTICS

# Calculating mean raw RTs and SDs per regions in a STRONG condition
strong <- spr %>%
  filter (verb_strength == 'strong') %>%
  filter (region == '1')
head (strong)
summary (strong$RT_raw)
sd(strong$RT_raw)

# Calculating 95% CIs per regions in a STRONG condition
strong_ci <- spr %>%
  filter (verb_strength == 'strong') %>%
  filter (region == '1') %>%
  summarise(RT_raw_mean = mean(RT_raw),
            RT_raw_ci = 1.96 * sd (RT_raw/sqrt(n())))
View(strong_ci)

# Calculating mean raw RTs and SDs per regions in a WEAK condition
weak <- spr %>%
  filter (verb_strength == 'weak') %>%
  filter (region == '7')
View (weakg)
summary (weak$RT_raw)
sd(weak$RT_raw)

# Calculating 95% CIs per regions in a WEAK condition
weak_ci <- spr %>%
  filter (verb_strength == 'weak') %>%
  filter (region == '1') %>%
  summarise(RT_raw_mean = mean(RT_raw),
            RT_raw_ci = 1.96 * sd (RT_raw/sqrt(n())))
View(weak_ci)

# STEP 2: DATA PREPARATION

# Checking raw RTs for normality
hist(spr$RT_raw) #right-skewed histogram
qqnorm(spr$RT_raw)
qqline(spr$RT_raw)
shapiro.test(spr$RT_raw) #Shapiro-Wilk normality test, p >.05

# Log-transforming raw RTs to the base of 'e' - 'natural logarithm' to overcome skewness
spr_log <- mutate(spr,logRT = log(spr$RT_raw))
head(spr_log)

# Checking log-transformed RTs for normality
hist(spr_log$logRT) 
qqnorm(spr_log$logRT)
qqline(spr_log$logRT)
## log-transformed RTs (log_RTs) follow a normal distribution

# Contrast coding the variable 'verb_strength' (weak vs. strong)
spr_log$verb_strength <- ifelse(spr_log$verb_strength == "weak", -0.5, 0.5)
spr_log$verb_strength


# Operationalization of RTs of Spanish sentences with constructions in the self-paced reading experiment
# 1) total logRTs for the sentence (whole sentence)
# 2) logRTs for region 3 (critical word)
# 3) logRTs for the construction (region 2 + region 3 + region 4 + region 5)

# 1) total logRT for the whole sentence
log.rt_whole <- spr_log %>%
  group_by(subject, item, EIT_score, VAC.type, verb_strength) %>%
  summarize(logRT_whole = sum(logRT))
head(log.rt_whole)

# 2) logRT for region 3 - critical word: preposition
log.rt_critical <- spr_log %>%
  group_by(subject, item, EIT_score, region, VAC.type) %>%
  filter (region == '3')
head(log.rt_critical)

# 3) logRTs for the construction (region 2 + region 3 + region 4 + region 5)
log.rt_constr <- spr_log %>%
  filter (region %in% c('2', '3', '4', '5')) %>%
  group_by(subject, EIT_score, item, VAC.type) %>%
  mutate(sum = sum(logRT)) %>% 
  as.data.frame()
head(log.rt_constr)

# STEP 3: DATA VISUALIZATION

# Building correlation scatterplots 'proficiencty ~ logRTs' for strong and weak conditions

### Filtering rows with strong verbs (0.5)
strong <- spr_log%>% 
  filter (verb_strength == '0.5')
head(strong)

### Filtering rows with weak verbs (-0.5)
weak <- spr_log %>% 
  filter (verb_strength == '-0.5')
head(weak)

# Building correlation scatterplot b/w Proficiency and logRTs for sentences with strong verbs
ggscatter(weak, x = "EIT_score", y = "logRT",
          add = "reg.line", conf.int = TRUE,
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Proficiency score", ylab = "logRTs for weak verb-VAC combinations")

# Building correlation scatterplot b/w Proficiency and residulized logRTs for sentences weak verbs
ggscatter (strong, x = "EIT_score", y = "logRT",
           add = "reg.line", conf.int = TRUE,
           cor.coef = TRUE, cor.method = "pearson",
           xlab = "Proficiency score", ylab = "logRTs for strong verb-VAC combinations")


# Generating line graph

### Participants' mean logRTs (in milliseconds) for construction types (VaN, VenN, VdeN, and VconN), presented by region. Error bars enclose 95% CIs.

pd <- position_dodge(width = 0.2)

l.graph <- spr_log %>% 
  select (logRT,region, VAC.type) %>% # Select relevant variables
  mutate(region = factor(region), #Convert grouping variables to factors
         VAC.type = factor(VAC.type, labels = c("VaN","VenN", "VdeN", "VconN"))) %>%
  group_by(region, VAC.type) %>% 
  summarise(logRT_mean = mean(logRT),
            logRT_ci = 1.96 * sd(logRT)/sqrt(n())) %>%
  ggplot(aes(x = region, y = logRT_mean, group = VAC.type)) + 
  geom_line(mapping = aes(color = VAC.type), position = pd) +
  geom_errorbar(aes(ymin = logRT_mean - logRT_ci, ymax = logRT_mean + logRT_ci),
                width = .1, position = pd, linetype = 1) +
  geom_point(size = 1, position = pd) +
  #geom_point(size = 3, position = pd, color = "white") +
  guides(linetype = guide_legend("Construction Type")) +
  labs(title = paste("Participants' mean log-transformed reading times (logRTs)",
                     "for Spanish construction types. Error bars represent 95% CIs.",
                     sep = "\n"),
       x = "Region",
       y = "Mean logRTs in ms") +
  theme(plot.title = element_text(hjust = 0.5))

l.graph



# STEP 4: MIXED-EFFECTS LINEAR MODELING

# 1) Mixed-effects regression models for the whole sentence logRTs

### Model 1 (a baseline model): logRTs ~ by-subject random intercepts
wh.model1 = lmer (logRT_whole ~ (1|subject), data = log.rt_whole, REML = FALSE)
summary(wh.model1)

### Model 2: logRTs ~ verb_strength + by-subject random intercepts
wh.model2 = lmer (logRT_whole ~ verb_strength + (1|subject), data = log.rt_whole, REML = FALSE)
summary(wh.model2)

### Model 3: logRTs ~ verb_strength + EIT_score + by-subject random intercepts
wh.model3 = lmer (logRT_whole ~ verb_strength + EIT_score + (1|subject), data = log.rt_whole, REML = FALSE)
summary(wh.model3)

### Model 4: logRTs ~ verb_strength + EIT_score + VAC_type + by-subject random intercepts
wh.model4 = lmer (logRT_whole ~ verb_strength + EIT_score + VAC.type + (1|subject), data = log.rt_whole, REML = FALSE)
summary(wh.model4)

### Model 5: logRTs ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-item random intercept
wh.model5 = lmer (logRT_whole ~ verb_strength + EIT_score + VAC.type + (1|subject) + (1|item), data = log.rt_whole, REML = FALSE)
summary(wh.model5)

### Model 6: logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept
wh.model6 = lmer (logRT_whole ~ verb_strength + EIT_score + VAC.type + (1+verb_strength|subject) + (1|item), data = log.rt_whole, REML = FALSE)
summary(wh.model6)

### Model 7: logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept + by-item random slopes
wh.model7 = lmer (logRT_whole ~ verb_strength + EIT_score + VAC.type + (1+verb_strength|subject) + (1+verb_strength|subject), data = log.rt_whole, REML = FALSE)
summary(wh.model7)

### Model 8:logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept + by-item random slopes
wh.model8 = lmer (logRT_whole ~ verb_strength + EIT_score + VAC.type + verb_strength:EIT_score:VAC.type + (1+verb_strength|subject) + (1+verb_strength|subject), data = log.rt_whole, REML = FALSE)
summary(wh.model8)

### Comparing models
anova(wh.model1, wh.model2, wh.model3, wh.model4, wh.model5, wh.model6, wh.model7, wh.model8)

summary(wh.model5)$coefficients

### Generating R2 values for the mixed models 
r.squaredGLMM(wh.model5)

### Calculating 95%CIs for estimates
confint(wh.model6)



# 2) Mixed-effects regression models for a critical word/preposition (region 3) in a Spanish sentence

### Model 1 (a baseline model): logRTs ~ by-subject random intercepts
r3.model1 = lmer (logRT ~ (1|subject), data = log.rt_critical, REML = FALSE)
summary(r3.model1)

### Model 2: R3 logRT ~ verb_strength + by-subject random intercepts
r3.model2 = lmer (logRT ~ verb_strength + (1|subject), data = log.rt_critical, REML = FALSE)
summary(r3.model2)

### Model 3: R3 logRT ~ verb_strength + EIT_score/proficiency + by-subject random intercepts
r3.model3 = lmer (logRT ~ verb_strength + EIT_score + (1|subject), data = log.rt_critical, REML = FALSE)
summary(r3.model3)

### Model 4: R3 logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts
r3.model4 = lmer (logRT ~ verb_strength + EIT_score + VAC.type + (1|subject), data = log.rt_critical, REML = FALSE)
summary(r3.model4)

### Model 5: R3 logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-item random intercept
r3.model5 = lmer (logRT ~ verb_strength + EIT_score + VAC.type + (1|subject) + (1|item), data = log.rt_critical, REML = FALSE)
summary(r3.model5)

### Model 6: R3 logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept
r3.model6 = lmer (logRT ~ verb_strength + EIT_score + VAC.type + (1+verb_strength|subject) + (1|item), data = log.rt_critical, REML = FALSE)
summary(r3.model6)

### Model 7: R3 logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept + by-item random slopes
r3.model7 = lmer (logRT ~ verb_strength + EIT_score + VAC.type + (1+verb_strength|subject) + (1+verb_strength|item), data = log.rt_critical, REML = FALSE)
summary(r3.model7)

### Model 8: R3 logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept + by-item random slopes
r3.model8 = lmer (logRT ~ verb_strength + EIT_score + VAC.type + verb_strength:EIT_score:VAC.type + (1+verb_strength|subject) + (1+verb_strength|item), data = log.rt_critical, REML = FALSE)
summary(r3.model8)

### Comparing 8 models
anova(r3.model1, r3.model2, r3.model3, r3.model4, r3.model5, r3.model6, r3.model7, r3.model8)
summary(r3.model5)$coefficients

### Generating R2 values 
r.squaredGLMM(r3.model5)

### Calculating 95%CIs for the estimates
confint(r3.model5)



# 3) Mixed-effects regression models for a construction in a sentence (region 2 + region 3 + region 4 + region 5)

### Model 1 (a baseline model): VAC logRTs ~ by-subject random intercepts
vac.model1 = lmer (VAC.RT ~ (1|subject), data = log.rt_constr, REML = FALSE)
summary(vac.model1)

### Model 2: VAC logRT ~ verb_strength + by-subject random intercepts
vac.model2 = lmer (VAC.RT ~ verb_strength + (1|subject), data = log.rt_constr, REML = FALSE)
summary(vac.model2)

### Model 3: VAC logRT ~ verb_strength + EIT_score/proficiency + by-subject random intercepts
vac.model3 = lmer (VAC.RT ~ verb_strength + EIT_score + (1|subject), data = log.rt_constr, REML = FALSE)
summary(vac.model3)

### Model 4: VAC logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts
vac.model4 = lmer (VAC.RT ~ verb_strength + EIT_score + VAC.type + (1|subject), data = log.rt_constr, REML = FALSE)
summary(vac.model4)

### Model 5: VAC logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-item random intercept
vac.model5 = lmer (VAC.RT ~ verb_strength + EIT_score + VAC.type + (1|subject) + (1|item), data = log.rt_constr, REML = FALSE)
summary(vac.model5)

### Model 6: VAC logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept
vac.model6 = lmer (VAC.RT ~ verb_strength + EIT_score + VAC.type + (1+verb_strength|subject) + (1|item), data = log.rt_constr, REML = FALSE)
summary(vac.model6)

### Model 7: VAC logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept + by-item random slopes
vac.model7 = lmer (VAC.RT ~ verb_strength + EIT_score + VAC.type + (1+verb_strength|subject) + (1+verb_strength|item), data = log.rt_constr, REML = FALSE)
summary(vac.model7)

### Model 8:VAC logRT ~ verb_strength + EIT_score/proficiency + VAC_type + by-subject random intercepts + by-subject random slopes + by-item random intercept + by-item random slopes
vac.model8 = lmer (VAC.RT ~ verb_strength + EIT_score + VAC.type + verb_strength:EIT_score:VAC.type + (1+verb_strength|item) + (1+verb_strength|subject), data = log.rt_constr , REML = FALSE)
summary(vac.model8)

### Comparing 8 models
anova(vac.model1, vac.model2, vac.model3, vac.model4, vac.model5, vac.model6, vac.model7, vac.model8)
summary(vac.model5)$coefficients

### Generating R2 values for the mixed models
r.squaredGLMM(vac.model5)

### Calculating 95%CIs for estimates
confint(vac.model5)
