
class Task:
    def __init__(self, description, task_id):
        self.description = description
        self.task_id = task_id

    def __str__(self):
        return f"Task ID: {self.task_id}, Description: {self.description}"
