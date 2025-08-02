class_name Helpers

static func Map(val:float, min1:float, max1:float, min2:float, max2:float) -> float: ##Remaps a value between the initial range (min1, max1) to an equivalant value in the target range(min2, max2). Using 0, 1 for min2, max2 is effectively a normalize operation.
	return  min2 + (max2 - min2) * ((val - min1) / (max1 - min1))