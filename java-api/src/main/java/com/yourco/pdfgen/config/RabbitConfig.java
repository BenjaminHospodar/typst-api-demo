package com.yourco.pdfgen.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import com.yourco.pdfgen.model.JobMessage;
import com.yourco.pdfgen.service.JobService;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.rabbit.retry.MessageRecoverer;
import org.springframework.amqp.rabbit.retry.RejectAndDontRequeueRecoverer;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

@Configuration
@EnableRabbit
@Import(RabbitAutoConfiguration.class)
@ConditionalOnProperty(name = "pdfgen.rabbit.enabled", havingValue = "true")
public class RabbitConfig {

    @Bean
    public Jackson2JsonMessageConverter jackson2JsonMessageConverter(ObjectMapper objectMapper) {
        ObjectMapper mqMapper = objectMapper.copy();
        mqMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        return new Jackson2JsonMessageConverter(mqMapper);
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory,
                                         Jackson2JsonMessageConverter converter) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(converter);
        template.setMandatory(false);
        return template;
    }

    @Bean
    public MessageRecoverer jobFailureRecoverer(JobService jobService, Jackson2JsonMessageConverter converter) {
        MessageRecoverer reject = new RejectAndDontRequeueRecoverer();
        return (message, cause) -> {
            try {
                Object payload = converter.fromMessage(message);
                if (payload instanceof JobMessage job) {
                    String msg = cause == null || cause.getMessage() == null
                            ? "retries exhausted"
                            : cause.getMessage();
                    jobService.markFailed(job.jobId(), job.form(), msg);
                }
            } catch (RuntimeException ignored) {
                // still DLQ the poison message
            }
            reject.recover(message, cause);
        };
    }

    @Bean
    public DirectExchange jobsExchange(PdfGenProperties props) {
        return new DirectExchange(props.rabbit().jobsExchange(), true, false);
    }

    @Bean
    public DirectExchange jobsDlx(PdfGenProperties props) {
        return new DirectExchange(props.rabbit().jobsDlx(), true, false);
    }

    @Bean
    public TopicExchange eventsExchange(PdfGenProperties props) {
        return new TopicExchange(props.rabbit().eventsExchange(), true, false);
    }

    @Bean
    public Queue jobsDlq(PdfGenProperties props) {
        return QueueBuilder.durable(props.rabbit().jobsDlq()).build();
    }

    @Bean
    public Queue jobsQueue(PdfGenProperties props) {
        return QueueBuilder.durable(props.rabbit().jobsQueue())
                .withArgument("x-dead-letter-exchange", props.rabbit().jobsDlx())
                .withArgument("x-dead-letter-routing-key", props.rabbit().jobsRoutingKey())
                .build();
    }

    @Bean
    public Queue eventsQueue(PdfGenProperties props) {
        return QueueBuilder.durable(props.rabbit().eventsQueue())
                .withArgument("x-message-ttl", 3_600_000)
                .withArgument("x-max-length", 10_000)
                .build();
    }

    @Bean
    public Binding jobsBinding(Queue jobsQueue, DirectExchange jobsExchange, PdfGenProperties props) {
        return BindingBuilder.bind(jobsQueue).to(jobsExchange).with(props.rabbit().jobsRoutingKey());
    }

    @Bean
    public Binding jobsDlqBinding(Queue jobsDlq, DirectExchange jobsDlx, PdfGenProperties props) {
        return BindingBuilder.bind(jobsDlq).to(jobsDlx).with(props.rabbit().jobsRoutingKey());
    }

    @Bean
    public Binding eventsBinding(Queue eventsQueue, TopicExchange eventsExchange) {
        return BindingBuilder.bind(eventsQueue).to(eventsExchange).with("job.*");
    }
}
