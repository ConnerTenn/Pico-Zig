pub const PIDcontrol = struct {
    const Self = @This();

    proportional_gain: f32,
    integral_gain: f32,
    derivative_gain: f32,

    last_error: f32 = 0,
    error_accumulator: f32 = 0,

    pub fn create(proportional_gain: f32, integral_gain: f32, derivative_gain: f32) Self {
        return Self{
            .proportional_gain = proportional_gain,
            .integral_gain = integral_gain,
            .derivative_gain = derivative_gain,
        };
    }

    pub fn update(self: *Self, delta_error: f32, delta_time_s: f32) f32 {
        //accumulate the error for the integral term
        self.error_accumulator += delta_error;

        //Calculate the three components
        const proportional = delta_error * self.proportional_gain;
        const derivative = (delta_error - self.last_error) / delta_time_s * self.derivative_gain;
        const integral = self.error_accumulator / delta_time_s * self.integral_gain;

        //Record the last error for the derivative term
        self.last_error = delta_error;

        return proportional + derivative + integral;
    }
};
