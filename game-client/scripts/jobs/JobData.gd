## JobData.gd
## Data model for a job and its skill requirements.
extends Resource
class_name JobData

@export var job_id: String = ""
@export var job_name: String = ""
@export var job_type: String = ""
@export var required_skill: String = ""
@export var required_skill_level: int = 1
@export var base_pay: int = 0
@export var description: String = ""
@export var district_id: String = ""
@export var active: bool = true

func to_dict() -> Dictionary:
	return {
		"job_id": job_id,
		"job_name": job_name,
		"job_type": job_type,
		"required_skill": required_skill,
		"required_skill_level": required_skill_level,
		"base_pay": base_pay,
		"description": description,
		"district_id": district_id,
		"active": active,
	}

static func from_dict(data: Dictionary) -> JobData:
	var job := JobData.new()
	job.job_id = data.get("job_id", "")
	job.job_name = data.get("job_name", "")
	job.job_type = data.get("job_type", "")
	job.required_skill = data.get("required_skill", "")
	job.required_skill_level = int(data.get("required_skill_level", 1))
	job.base_pay = int(data.get("base_pay", 0))
	job.description = data.get("description", "")
	job.district_id = data.get("district_id", "")
	job.active = bool(data.get("active", true))
	return job
